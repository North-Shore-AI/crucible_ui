defmodule CrucibleUIWeb.EnsembleLive do
  @moduledoc """
  LiveView for ensemble voting dashboard.
  """
  use CrucibleUIWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Ensemble Dashboard")
     |> assign(:voting_strategies, ["majority", "weighted", "best_confidence", "unanimous"])
     |> assign(:selected_strategy, "majority")
     |> assign(:models, [])
     |> assign(:accuracy_data, [])}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_strategy", %{"strategy" => strategy}, socket) do
    {:noreply, assign(socket, :selected_strategy, strategy)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Ensemble Dashboard
        <:subtitle>Multi-model voting and performance comparison</:subtitle>
      </.header>

      <div class="mt-6">
        <h3 class="text-sm font-medium text-gray-700 mb-2">Voting Strategy</h3>
        <div class="flex gap-2">
          <%= for strategy <- @voting_strategies do %>
            <button
              phx-click="select_strategy"
              phx-value-strategy={strategy}
              class={[
                "px-3 py-1 rounded text-sm font-medium",
                if(@selected_strategy == strategy,
                  do: "bg-zinc-900 text-white",
                  else: "bg-gray-100 text-gray-700 hover:bg-gray-200"
                )
              ]}
            >
              <%= String.replace(strategy, "_", " ") |> String.capitalize() %>
            </button>
          <% end %>
        </div>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Model Performance</h3>
          <div class="space-y-3">
            <div class="flex justify-between items-center">
              <span class="text-sm">GPT-4</span>
              <div class="flex items-center gap-2">
                <div class="w-32 bg-gray-200 rounded-full h-2">
                  <div class="bg-blue-600 h-2 rounded-full" style="width: 92%"></div>
                </div>
                <span class="text-sm font-mono">92%</span>
              </div>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-sm">Claude-3</span>
              <div class="flex items-center gap-2">
                <div class="w-32 bg-gray-200 rounded-full h-2">
                  <div class="bg-blue-600 h-2 rounded-full" style="width: 89%"></div>
                </div>
                <span class="text-sm font-mono">89%</span>
              </div>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-sm">Gemini</span>
              <div class="flex items-center gap-2">
                <div class="w-32 bg-gray-200 rounded-full h-2">
                  <div class="bg-blue-600 h-2 rounded-full" style="width: 87%"></div>
                </div>
                <span class="text-sm font-mono">87%</span>
              </div>
            </div>
            <div class="flex justify-between items-center border-t pt-2 mt-2">
              <span class="text-sm font-semibold">Ensemble (<%= @selected_strategy %>)</span>
              <div class="flex items-center gap-2">
                <div class="w-32 bg-gray-200 rounded-full h-2">
                  <div class="bg-green-600 h-2 rounded-full" style="width: 96%"></div>
                </div>
                <span class="text-sm font-mono font-semibold">96%</span>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Voting Statistics</h3>
          <dl class="space-y-3">
            <div class="flex justify-between">
              <dt class="text-sm text-gray-500">Total Predictions</dt>
              <dd class="text-sm font-mono">1,234</dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-sm text-gray-500">Unanimous Agreement</dt>
              <dd class="text-sm font-mono">78%</dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-sm text-gray-500">Split Votes</dt>
              <dd class="text-sm font-mono">22%</dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-sm text-gray-500">Avg. Confidence</dt>
              <dd class="text-sm font-mono">0.89</dd>
            </div>
          </dl>
        </div>
      </div>

      <div class="mt-8 bg-white shadow rounded-lg p-6">
        <h3 class="text-lg font-semibold mb-4">Strategy Comparison</h3>
        <p class="text-sm text-gray-500">
          Placeholder for strategy comparison chart. Integration with Chart.js pending.
        </p>
      </div>
    </div>
    """
  end
end
