defmodule Crucible.UI.ExperimentShowLive do
  @moduledoc """
  LiveView for showing experiment details.

  This LiveView is host-agnostic and uses the backend behaviour for data operations.
  """
  use Phoenix.LiveView

  import Crucible.UI.Components
  alias Phoenix.LiveView.JS

  @impl true
  def mount(%{"id" => id}, session, socket) do
    backend = session["crucible_backend"]
    pubsub = session["pubsub"] || infer_pubsub(backend)

    socket =
      socket
      |> assign(:backend, backend)
      |> assign(:pubsub, pubsub)
      |> assign(:experiment_id, id)

    if connected?(socket) do
      topic = get_topic(backend, :experiment, id)
      Phoenix.PubSub.subscribe(pubsub, topic)

      runs_topic = get_topic(backend, :experiment_runs, id)
      Phoenix.PubSub.subscribe(pubsub, runs_topic)
    end

    case backend.get_experiment_with_associations(id) do
      {:ok, experiment} ->
        {:ok,
         socket
         |> assign(:experiment, experiment)
         |> assign(:runs, get_field(experiment, :runs, []))
         |> assign(:results, get_field(experiment, :statistical_results, []))}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Experiment not found")
         |> redirect(to: "/experiments")}

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Failed to load experiment")
         |> redirect(to: "/experiments")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    experiment = socket.assigns.experiment
    socket |> assign(:page_title, get_field(experiment, :name, "Experiment"))
  end

  defp apply_action(socket, :edit, _params) do
    experiment = socket.assigns.experiment
    socket |> assign(:page_title, "Edit #{get_field(experiment, :name, "Experiment")}")
  end

  @impl true
  def handle_info({:experiment_updated, experiment}, socket) do
    {:noreply, assign(socket, :experiment, experiment)}
  end

  @impl true
  def handle_info({:run_created, run}, socket) do
    {:noreply, assign(socket, :runs, [run | socket.assigns.runs])}
  end

  @impl true
  def handle_info({:run_updated, run}, socket) do
    runs =
      Enum.map(socket.assigns.runs, fn r ->
        if get_field(r, :id) == get_field(run, :id), do: run, else: r
      end)

    {:noreply, assign(socket, :runs, runs)}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def handle_event("start", _params, socket) do
    backend = socket.assigns.backend
    id = socket.assigns.experiment_id

    case backend.start_experiment(id) do
      {:ok, experiment} ->
        {:noreply, assign(socket, :experiment, experiment)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to start experiment")}
    end
  end

  @impl true
  def handle_event("complete", _params, socket) do
    backend = socket.assigns.backend
    id = socket.assigns.experiment_id

    case backend.complete_experiment(id) do
      {:ok, experiment} ->
        {:noreply, assign(socket, :experiment, experiment)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to complete experiment")}
    end
  end

  @impl true
  def render(assigns) do
    # Extract experiment fields for template (handles both struct and map)
    assigns =
      assign(assigns,
        experiment_name: get_field(assigns.experiment, :name, "Experiment"),
        experiment_description: get_field(assigns.experiment, :description),
        experiment_id: get_field(assigns.experiment, :id),
        experiment_status: get_field(assigns.experiment, :status, "pending"),
        experiment_started_at: get_field(assigns.experiment, :started_at),
        experiment_completed_at: get_field(assigns.experiment, :completed_at),
        experiment_config: get_field(assigns.experiment, :config)
      )

    ~H"""
    <div>
      <.header>
        <%= @experiment_name %>
        <:subtitle><%= @experiment_description %></:subtitle>
        <:actions>
          <.link patch={"/experiments/#{@experiment_id}/edit"} phx-click={JS.push_focus()}>
            <.button>Edit</.button>
          </.link>
        </:actions>
      </.header>

      <.list>
        <:item title="Status">
          <.status_badge status={@experiment_status} />
        </:item>
        <:item title="Started"><%= format_datetime(@experiment_started_at) %></:item>
        <:item title="Completed"><%= format_datetime(@experiment_completed_at) %></:item>
        <:item title="Configuration">
          <pre class="text-xs bg-gray-50 p-2 rounded"><%= format_json(@experiment_config) %></pre>
        </:item>
      </.list>

      <div class="mt-8 flex gap-4">
        <.button :if={@experiment_status == "pending"} phx-click="start">
          Start Experiment
        </.button>
        <.button :if={@experiment_status == "running"} phx-click="complete">
          Complete
        </.button>
      </div>

      <div class="mt-8">
        <h3 class="text-lg font-semibold">Runs (<%= length(@runs) %>)</h3>
        <div class="mt-4 space-y-2">
          <%= for run <- @runs do %>
            <div class="border rounded p-3">
              <div class="flex justify-between items-center">
                <.link
                  navigate={"/runs/#{get_field(run, :id)}"}
                  class="font-medium hover:text-zinc-700"
                >
                  Run #<%= get_field(run, :id) %>
                </.link>
                <.status_badge status={get_field(run, :status, "pending")} />
              </div>
            </div>
          <% end %>
          <%= if @runs == [] do %>
            <p class="text-sm text-gray-500">No runs yet</p>
          <% end %>
        </div>
      </div>

      <.back navigate="/experiments">Back to experiments</.back>

      <.modal
        :if={@live_action == :edit}
        id="experiment-modal"
        show
        on_cancel={JS.patch("/experiments/#{@experiment_id}")}
      >
        <div class="space-y-4">
          <h2 class="text-xl font-semibold">Edit Experiment</h2>
          <p class="text-sm text-gray-600">
            Note: Form component requires host app implementation.
          </p>
        </div>
      </.modal>
    </div>
    """
  end

  # Helper functions
  defp format_datetime(nil), do: "Not started"
  defp format_datetime(""), do: "Not started"

  defp format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")
  end

  defp format_datetime(%NaiveDateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S")
  end

  defp format_datetime(str) when is_binary(str), do: str
  defp format_datetime(_), do: "N/A"

  defp format_json(nil), do: "{}"
  defp format_json(%{} = map), do: Jason.encode!(map, pretty: true)
  defp format_json(data) when is_map(data), do: Jason.encode!(data, pretty: true)
  defp format_json(_), do: "{}"

  defp get_topic(backend, :experiment, id) do
    if function_exported?(backend, :pubsub_topic, 2) do
      backend.pubsub_topic(:experiment, id)
    else
      "experiment:#{id}"
    end
  end

  defp get_topic(backend, :experiment_runs, id) do
    if function_exported?(backend, :pubsub_topic, 2) do
      backend.pubsub_topic(:experiment_runs, id)
    else
      "experiment:#{id}:runs"
    end
  end

  defp infer_pubsub(backend) do
    module_parts = Module.split(backend)

    case module_parts do
      [app | _] -> Module.concat([app, "PubSub"])
      _ -> raise "Cannot infer PubSub module from backend #{inspect(backend)}"
    end
  end

  # Helper to get field from struct or map
  defp get_field(data, key, default \\ nil)
  defp get_field(%{} = data, key, default) when is_struct(data), do: Map.get(data, key, default)
  defp get_field(%{} = data, key, default), do: Map.get(data, key, default)
  defp get_field(_, _, default), do: default
end
