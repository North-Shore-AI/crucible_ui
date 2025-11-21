defmodule CrucibleUIWeb.DashboardLive do
  @moduledoc """
  Main dashboard LiveView showing system overview.
  """
  use CrucibleUIWeb, :live_view

  alias CrucibleUI.Experiments
  alias CrucibleUI.Runs
  alias CrucibleUI.Statistics

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CrucibleUI.PubSub, "experiments:list")
      Phoenix.PubSub.subscribe(CrucibleUI.PubSub, "runs:list")
    end

    {:ok, assign_stats(socket)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Dashboard")
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
    experiments = Experiments.list_experiments()
    runs = Runs.list_runs()
    results = Statistics.list_results()

    running_experiments = Enum.count(experiments, &(&1.status == "running"))
    completed_experiments = Enum.count(experiments, &(&1.status == "completed"))
    running_runs = Enum.count(runs, &(&1.status == "running"))
    significant_results = Enum.count(results, &(&1.p_value && &1.p_value < 0.05))

    socket
    |> assign(:total_experiments, length(experiments))
    |> assign(:running_experiments, running_experiments)
    |> assign(:completed_experiments, completed_experiments)
    |> assign(:total_runs, length(runs))
    |> assign(:running_runs, running_runs)
    |> assign(:significant_results, significant_results)
    |> assign(:recent_experiments, Enum.take(experiments, 5))
    |> assign(:recent_runs, Enum.take(runs, 5))
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
        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="p-5">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <.icon name="hero-beaker" class="h-6 w-6 text-gray-400" />
              </div>
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="text-sm font-medium text-gray-500 truncate">Total Experiments</dt>
                  <dd class="text-lg font-semibold text-gray-900"><%= @total_experiments %></dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="p-5">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <.icon name="hero-play" class="h-6 w-6 text-green-400" />
              </div>
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="text-sm font-medium text-gray-500 truncate">Running</dt>
                  <dd class="text-lg font-semibold text-gray-900"><%= @running_experiments %></dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="p-5">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <.icon name="hero-chart-bar" class="h-6 w-6 text-blue-400" />
              </div>
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="text-sm font-medium text-gray-500 truncate">Total Runs</dt>
                  <dd class="text-lg font-semibold text-gray-900"><%= @total_runs %></dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="p-5">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <.icon name="hero-check-circle" class="h-6 w-6 text-emerald-400" />
              </div>
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="text-sm font-medium text-gray-500 truncate">Significant Results</dt>
                  <dd class="text-lg font-semibold text-gray-900"><%= @significant_results %></dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
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
                        navigate={~p"/experiments/#{experiment.id}"}
                        class="text-sm font-medium text-zinc-900 hover:text-zinc-700"
                      >
                        <%= experiment.name %>
                      </.link>
                      <span class={[
                        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                        status_color(experiment.status)
                      ]}>
                        <%= experiment.status %>
                      </span>
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
                        navigate={~p"/runs/#{run.id}"}
                        class="text-sm font-medium text-zinc-900 hover:text-zinc-700"
                      >
                        Run #<%= run.id %>
                      </.link>
                      <span class={[
                        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                        status_color(run.status)
                      ]}>
                        <%= run.status %>
                      </span>
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

  defp status_color("pending"), do: "bg-gray-100 text-gray-800"
  defp status_color("running"), do: "bg-blue-100 text-blue-800"
  defp status_color("completed"), do: "bg-green-100 text-green-800"
  defp status_color("failed"), do: "bg-red-100 text-red-800"
  defp status_color("cancelled"), do: "bg-yellow-100 text-yellow-800"
  defp status_color(_), do: "bg-gray-100 text-gray-800"
end
