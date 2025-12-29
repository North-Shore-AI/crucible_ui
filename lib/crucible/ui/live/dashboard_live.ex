defmodule Crucible.UI.DashboardLive do
  @moduledoc """
  Main dashboard LiveView showing system overview.

  This LiveView is host-agnostic and uses the backend behaviour for data operations.
  """
  use Phoenix.LiveView

  # Import only the components needed from the feature module
  import Crucible.UI.Components

  @impl true
  def mount(_params, session, socket) do
    backend = session["crucible_backend"]
    telemetry_prefix = session["telemetry_prefix"] || [:crucible, :ui]
    pubsub = session["pubsub"] || infer_pubsub(backend)

    socket =
      socket
      |> assign(:backend, backend)
      |> assign(:telemetry_prefix, telemetry_prefix)
      |> assign(:pubsub, pubsub)

    if connected?(socket) do
      # Subscribe to updates - use backend's topic if available
      topic = get_topic(backend, :experiments_list)
      Phoenix.PubSub.subscribe(pubsub, topic)

      topic = get_topic(backend, :runs_list)
      Phoenix.PubSub.subscribe(pubsub, topic)
    end

    {:ok, assign_stats(socket)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "Dashboard")}
  end

  @impl true
  def handle_info({:experiment_created, _experiment}, socket) do
    {:noreply, assign_stats(socket)}
  end

  @impl true
  def handle_info({:experiment_updated, _experiment}, socket) do
    {:noreply, assign_stats(socket)}
  end

  @impl true
  def handle_info({:run_created, _run}, socket) do
    {:noreply, assign_stats(socket)}
  end

  @impl true
  def handle_info({:run_updated, _run}, socket) do
    {:noreply, assign_stats(socket)}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  defp assign_stats(socket) do
    backend = socket.assigns.backend

    # Get system statistics from backend
    {:ok, stats} = backend.get_system_statistics()

    socket
    |> assign(:total_experiments, stats[:total_experiments] || 0)
    |> assign(:running_experiments, stats[:running_experiments] || 0)
    |> assign(:completed_experiments, stats[:completed_experiments] || 0)
    |> assign(:total_runs, stats[:total_runs] || 0)
    |> assign(:running_runs, stats[:running_runs] || 0)
    |> assign(:significant_results, stats[:significant_results] || 0)
    |> assign(:recent_experiments, stats[:recent_experiments] || [])
    |> assign(:recent_runs, stats[:recent_runs] || [])
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Dashboard
        <:subtitle>System overview and key metrics</:subtitle>
      </.header>

      <div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        <.stat_card
          icon="hero-beaker"
          label="Total Experiments"
          value={@total_experiments}
          icon_class="text-gray-400"
        />

        <.stat_card
          icon="hero-play"
          label="Running"
          value={@running_experiments}
          icon_class="text-green-400"
        />

        <.stat_card
          icon="hero-chart-bar"
          label="Total Runs"
          value={@total_runs}
          icon_class="text-blue-400"
        />

        <.stat_card
          icon="hero-check-circle"
          label="Significant Results"
          value={@significant_results}
          icon_class="text-emerald-400"
        />
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="bg-white shadow rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg font-medium leading-6 text-gray-900">Recent Experiments</h3>
            <div class="mt-4">
              <ul role="list" class="divide-y divide-gray-200">
                <%= for experiment <- @recent_experiments do %>
                  <li class="py-3">
                    <div class="flex items-center justify-between">
                      <.link
                        navigate={experiment_path(experiment)}
                        class="text-sm font-medium text-zinc-900 hover:text-zinc-700"
                      >
                        <%= experiment.name || "Experiment ##{experiment.id}" %>
                      </.link>
                      <.status_badge status={experiment.status || "pending"} />
                    </div>
                  </li>
                <% end %>
              </ul>
              <%= if @recent_experiments == [] do %>
                <p class="text-sm text-gray-500">No experiments yet</p>
              <% end %>
            </div>
          </div>
        </div>

        <div class="bg-white shadow rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg font-medium leading-6 text-gray-900">Recent Runs</h3>
            <div class="mt-4">
              <ul role="list" class="divide-y divide-gray-200">
                <%= for run <- @recent_runs do %>
                  <li class="py-3">
                    <div class="flex items-center justify-between">
                      <.link
                        navigate={run_path(run)}
                        class="text-sm font-medium text-zinc-900 hover:text-zinc-700"
                      >
                        Run #<%= run.id %>
                      </.link>
                      <.status_badge status={run.status || "pending"} />
                    </div>
                  </li>
                <% end %>
              </ul>
              <%= if @recent_runs == [] do %>
                <p class="text-sm text-gray-500">No runs yet</p>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Path helpers (agnostic to host routing)
  defp experiment_path(experiment) do
    "/experiments/#{experiment.id}"
  end

  defp run_path(run) do
    "/runs/#{run.id}"
  end

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
    # Try to extract app name from backend module
    # e.g., CrucibleUI.Backend -> CrucibleUI.PubSub
    module_parts = Module.split(backend)

    app_module =
      case module_parts do
        [app | _] -> Module.concat([app, "PubSub"])
        _ -> raise "Cannot infer PubSub module from backend #{inspect(backend)}"
      end

    app_module
  end
end
