defmodule CrucibleUIWeb.RunLive.Show do
  @moduledoc """
  LiveView for showing run details with real-time metrics.
  """
  use CrucibleUIWeb, :live_view

  alias CrucibleUI.Runs
  alias CrucibleUI.Telemetry

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CrucibleUI.PubSub, "run:#{id}")
      Phoenix.PubSub.subscribe(CrucibleUI.PubSub, "run:#{id}:telemetry")
    end

    run = Runs.get_run_with_events!(id)
    events = Telemetry.list_events_for_run(id)

    {:ok,
     socket
     |> assign(:run, run)
     |> assign(:events, Enum.take(events, 100))
     |> assign(:results, run.statistical_results)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "Run ##{socket.assigns.run.id}")}
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
    {:ok, run} = Runs.start_run(socket.assigns.run)
    {:noreply, assign(socket, :run, run)}
  end

  @impl true
  def handle_event("complete", _params, socket) do
    {:ok, run} = Runs.complete_run(socket.assigns.run)
    {:noreply, assign(socket, :run, run)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Run #<%= @run.id %>
        <:subtitle>Experiment: <%= @run.experiment.name %></:subtitle>
      </.header>

      <.list>
        <:item title="Status">
          <span class={[
            "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
            status_color(@run.status)
          ]}>
            <%= @run.status %>
          </span>
        </:item>
        <:item title="Started"><%= @run.started_at || "Not started" %></:item>
        <:item title="Completed"><%= @run.completed_at || "Not completed" %></:item>
        <:item title="Checkpoint"><%= @run.checkpoint_path || "None" %></:item>
      </.list>

      <div class="mt-8 flex gap-4">
        <.button :if={@run.status == "pending"} phx-click="start">Start Run</.button>
        <.button :if={@run.status == "running"} phx-click="complete">Complete</.button>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Metrics</h3>
          <pre class="text-xs bg-gray-50 p-2 rounded overflow-auto max-h-64"><%= Jason.encode!(@run.metrics, pretty: true) %></pre>
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Hyperparameters</h3>
          <pre class="text-xs bg-gray-50 p-2 rounded overflow-auto max-h-64"><%= Jason.encode!(@run.hyperparameters, pretty: true) %></pre>
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
                      <%= Calendar.strftime(event.recorded_at, "%H:%M:%S") %>
                    </td>
                    <td class="px-4 py-2 text-xs font-medium"><%= event.event_type %></td>
                    <td class="px-4 py-2 text-xs text-gray-600 truncate max-w-xs">
                      <%= inspect(event.data) %>
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

      <.back navigate={~p"/experiments/#{@run.experiment_id}"}>Back to experiment</.back>
    </div>
    """
  end

  defp status_color("pending"), do: "bg-gray-100 text-gray-800"
  defp status_color("running"), do: "bg-blue-100 text-blue-800"
  defp status_color("completed"), do: "bg-green-100 text-green-800"
  defp status_color("failed"), do: "bg-red-100 text-red-800"
  defp status_color(_), do: "bg-gray-100 text-gray-800"
end
