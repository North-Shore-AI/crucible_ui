defmodule Crucible.UI.ExperimentListLive do
  @moduledoc """
  LiveView for listing and managing experiments.

  This LiveView is host-agnostic and uses the backend behaviour for data operations.
  """
  use Phoenix.LiveView

  import Crucible.UI.Components
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, session, socket) do
    backend = session["crucible_backend"]
    pubsub = session["pubsub"] || infer_pubsub(backend)

    socket =
      socket
      |> assign(:backend, backend)
      |> assign(:pubsub, pubsub)

    if connected?(socket) do
      topic = get_topic(backend, :experiments_list)
      Phoenix.PubSub.subscribe(pubsub, topic)
    end

    {:ok, experiments} = backend.list_experiments([])

    {:ok, stream(socket, :experiments, experiments)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Experiments")
    |> assign(:experiment, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Experiment")
    |> assign(:experiment, %{})
  end

  @impl true
  def handle_info({:experiment_created, experiment}, socket) do
    {:noreply, stream_insert(socket, :experiments, experiment, at: 0)}
  end

  @impl true
  def handle_info({:experiment_updated, experiment}, socket) do
    {:noreply, stream_insert(socket, :experiments, experiment)}
  end

  @impl true
  def handle_info({:experiment_deleted, experiment}, socket) do
    {:noreply, stream_delete(socket, :experiments, experiment)}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    backend = socket.assigns.backend

    case backend.delete_experiment(id) do
      {:ok, experiment} ->
        {:noreply, stream_delete(socket, :experiments, experiment)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete experiment")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Experiments
        <:actions>
          <.link patch="/experiments/new">
            <.button>New Experiment</.button>
          </.link>
        </:actions>
      </.header>

      <.table
        id="experiments"
        rows={@streams.experiments}
        row_click={fn {_id, experiment} -> JS.navigate("/experiments/#{experiment.id}") end}
      >
        <:col :let={{_id, experiment}} label="Name"><%= experiment.name %></:col>
        <:col :let={{_id, experiment}} label="Status">
          <.status_badge status={experiment.status} />
        </:col>
        <:col :let={{_id, experiment}} label="Created">
          <%= format_datetime(experiment.inserted_at) %>
        </:col>
        <:action :let={{_id, experiment}}>
          <.link navigate={"/experiments/#{experiment.id}"}>Show</.link>
        </:action>
        <:action :let={{id, experiment}}>
          <.link
            phx-click={JS.push("delete", value: %{id: experiment.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>

      <.modal
        :if={@live_action == :new}
        id="experiment-modal"
        show
        on_cancel={JS.patch("/experiments")}
      >
        <div class="space-y-4">
          <h2 class="text-xl font-semibold">New Experiment</h2>
          <p class="text-sm text-gray-600">
            Note: Form component requires host app implementation.
            This is a placeholder for the composable pattern.
          </p>
        </div>
      </.modal>
    </div>
    """
  end

  # Helper to format datetime (host-agnostic)
  defp format_datetime(nil), do: "N/A"

  defp format_datetime(datetime) when is_binary(datetime), do: datetime

  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end

  defp format_datetime(%NaiveDateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end

  defp format_datetime(_), do: "N/A"

  # Get PubSub topic from backend or use default
  defp get_topic(backend, resource) do
    if function_exported?(backend, :pubsub_topic, 2) do
      backend.pubsub_topic(resource, nil)
    else
      "#{resource}"
    end
  end

  # Infer PubSub module from backend module name
  defp infer_pubsub(backend) do
    module_parts = Module.split(backend)

    app_module =
      case module_parts do
        [app | _] -> Module.concat([app, "PubSub"])
        _ -> raise "Cannot infer PubSub module from backend #{inspect(backend)}"
      end

    app_module
  end

  defp hide(js, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end
end
