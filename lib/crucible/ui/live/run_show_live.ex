defmodule Crucible.UI.RunShowLive do
  @moduledoc """
  LiveView for showing run details with real-time metrics.

  This LiveView is host-agnostic and uses the backend behaviour for data operations.
  """
  use Phoenix.LiveView

  import Crucible.UI.Components

  @impl true
  def mount(%{"id" => id}, session, socket) do
    backend = session["crucible_backend"]
    pubsub = session["pubsub"] || infer_pubsub(backend)

    socket =
      socket
      |> assign(:backend, backend)
      |> assign(:pubsub, pubsub)
      |> assign(:run_id, id)

    if connected?(socket) do
      topic = get_topic(backend, :run, id)
      Phoenix.PubSub.subscribe(pubsub, topic)

      telemetry_topic = get_topic(backend, :run_telemetry, id)
      Phoenix.PubSub.subscribe(pubsub, telemetry_topic)
    end

    case backend.get_run(id) do
      {:ok, run} ->
        {:ok, events} = backend.list_telemetry_events(id, limit: 100)

        {:ok,
         socket
         |> assign(:run, run)
         |> assign(:events, events)
         |> assign(:results, get_field(run, :statistical_results, []))}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Run not found")
         |> redirect(to: "/experiments")}

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Failed to load run")
         |> redirect(to: "/experiments")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "Run ##{get_field(socket.assigns.run, :id)}")}
  end

  @impl true
  def handle_info({:run_updated, run}, socket) do
    {:noreply, assign(socket, :run, run)}
  end

  @impl true
  def handle_info({:telemetry_event, event}, socket) do
    events = [event | socket.assigns.events] |> Enum.take(100)
    {:noreply, assign(socket, :events, events)}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def handle_event("start", _params, socket) do
    backend = socket.assigns.backend
    id = socket.assigns.run_id

    case backend.start_run(id) do
      {:ok, run} ->
        {:noreply, assign(socket, :run, run)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to start run")}
    end
  end

  @impl true
  def handle_event("complete", _params, socket) do
    backend = socket.assigns.backend
    id = socket.assigns.run_id

    case backend.complete_run(id) do
      {:ok, run} ->
        {:noreply, assign(socket, :run, run)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to complete run")}
    end
  end

  @impl true
  def render(assigns) do
    # Extract run fields for template (handles both struct and map)
    experiment = get_field(assigns.run, :experiment)

    assigns =
      assign(assigns,
        run_id: get_field(assigns.run, :id),
        run_status: get_field(assigns.run, :status, "pending"),
        run_started_at: get_field(assigns.run, :started_at),
        run_completed_at: get_field(assigns.run, :completed_at),
        run_checkpoint_path: get_field(assigns.run, :checkpoint_path),
        run_metrics: get_field(assigns.run, :metrics),
        run_hyperparameters: get_field(assigns.run, :hyperparameters),
        run_experiment_id: get_field(assigns.run, :experiment_id),
        experiment_name: (experiment && get_field(experiment, :name, "N/A")) || "N/A"
      )

    ~H"""
    <div>
      <.header>
        Run #<%= @run_id %>
        <:subtitle>Experiment: <%= @experiment_name %></:subtitle>
      </.header>

      <.list>
        <:item title="Status">
          <.status_badge status={@run_status} />
        </:item>
        <:item title="Started"><%= format_datetime(@run_started_at) %></:item>
        <:item title="Completed"><%= format_datetime(@run_completed_at) %></:item>
        <:item title="Checkpoint"><%= @run_checkpoint_path || "None" %></:item>
      </.list>

      <div class="mt-8 flex gap-4">
        <.button :if={@run_status == "pending"} phx-click="start">Start Run</.button>
        <.button :if={@run_status == "running"} phx-click="complete">Complete</.button>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Metrics</h3>
          <pre class="text-xs bg-gray-50 p-2 rounded overflow-auto max-h-64"><%= format_json(@run_metrics) %></pre>
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Hyperparameters</h3>
          <pre class="text-xs bg-gray-50 p-2 rounded overflow-auto max-h-64"><%= format_json(@run_hyperparameters) %></pre>
        </div>
      </div>

      <div class="mt-8">
        <h3 class="text-lg font-semibold mb-4">Telemetry Events (<%= length(@events) %>)</h3>
        <div class="bg-white shadow rounded-lg overflow-hidden">
          <div class="max-h-96 overflow-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Time
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Type
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Data
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200">
                <%= for event <- @events do %>
                  <tr>
                    <td class="px-4 py-2 text-xs text-gray-500">
                      <%= format_time(get_field(event, :recorded_at)) %>
                    </td>
                    <td class="px-4 py-2 text-xs font-medium">
                      <%= get_field(event, :event_type) %>
                    </td>
                    <td class="px-4 py-2 text-xs text-gray-600 truncate max-w-xs">
                      <%= inspect(get_field(event, :data)) %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
            <%= if @events == [] do %>
              <p class="p-4 text-sm text-gray-500">No telemetry events yet</p>
            <% end %>
          </div>
        </div>
      </div>

      <.back navigate={"/experiments/#{@run_experiment_id}"}>Back to experiment</.back>
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

  defp format_time(nil), do: "N/A"

  defp format_time(%DateTime{} = dt) do
    Calendar.strftime(dt, "%H:%M:%S")
  end

  defp format_time(%NaiveDateTime{} = dt) do
    Calendar.strftime(dt, "%H:%M:%S")
  end

  defp format_time(str) when is_binary(str), do: str
  defp format_time(_), do: "N/A"

  defp format_json(nil), do: "{}"
  defp format_json(%{} = map), do: Jason.encode!(map, pretty: true)
  defp format_json(data) when is_map(data), do: Jason.encode!(data, pretty: true)
  defp format_json(_), do: "{}"

  defp get_topic(backend, :run, id) do
    if function_exported?(backend, :pubsub_topic, 2) do
      backend.pubsub_topic(:run, id)
    else
      "run:#{id}"
    end
  end

  defp get_topic(backend, :run_telemetry, id) do
    if function_exported?(backend, :pubsub_topic, 2) do
      backend.pubsub_topic(:run_telemetry, id)
    else
      "run:#{id}:telemetry"
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
