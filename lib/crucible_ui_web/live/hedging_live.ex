defmodule CrucibleUIWeb.HedgingLive do
  @moduledoc """
  LiveView for request hedging metrics and latency analysis.
  """
  use CrucibleUIWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Hedging Metrics")
     |> assign(:strategies, ["fixed", "percentile", "adaptive", "workload_aware"])
     |> assign(:selected_strategy, "percentile")}
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
        Hedging Metrics
        <:subtitle>Latency reduction and request hedging performance</:subtitle>
      </.header>

      <div class="mt-6">
        <h3 class="text-sm font-medium text-gray-700 mb-2">Hedging Strategy</h3>
        <div class="flex gap-2">
          <%= for strategy <- @strategies do %>
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

      <div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="p-5">
            <div class="flex items-center">
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="text-sm font-medium text-gray-500 truncate">P50 Latency</dt>
                  <dd class="text-lg font-semibold text-gray-900">45ms</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="p-5">
            <div class="flex items-center">
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="text-sm font-medium text-gray-500 truncate">P95 Latency</dt>
                  <dd class="text-lg font-semibold text-gray-900">120ms</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="p-5">
            <div class="flex items-center">
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="text-sm font-medium text-gray-500 truncate">P99 Latency</dt>
                  <dd class="text-lg font-semibold text-green-600">180ms</dd>
                  <dd class="text-xs text-gray-500">-65% from baseline</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="p-5">
            <div class="flex items-center">
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="text-sm font-medium text-gray-500 truncate">Cost Overhead</dt>
                  <dd class="text-lg font-semibold text-yellow-600">+8%</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Latency Distribution</h3>
          <p class="text-sm text-gray-500">
            Placeholder for latency histogram. Integration with Chart.js pending.
          </p>
          <div class="mt-4 h-48 bg-gray-50 rounded flex items-center justify-center">
            <span class="text-gray-400">Latency Histogram</span>
          </div>
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Circuit Breaker Status</h3>
          <div class="space-y-3">
            <div class="flex justify-between items-center">
              <span class="text-sm">Primary Backend</span>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                Closed
              </span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-sm">Secondary Backend</span>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                Closed
              </span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-sm">Tertiary Backend</span>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                Half-Open
              </span>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-8 bg-white shadow rounded-lg p-6">
        <h3 class="text-lg font-semibold mb-4">Hedging Effectiveness</h3>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead>
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                  Strategy
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                  P99 Reduction
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                  Cost Increase
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                  Effectiveness
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr>
                <td class="px-4 py-3 text-sm">Fixed</td>
                <td class="px-4 py-3 text-sm font-mono">-50%</td>
                <td class="px-4 py-3 text-sm font-mono">+15%</td>
                <td class="px-4 py-3 text-sm font-mono">3.3x</td>
              </tr>
              <tr class={if @selected_strategy == "percentile", do: "bg-blue-50"}>
                <td class="px-4 py-3 text-sm font-medium">Percentile</td>
                <td class="px-4 py-3 text-sm font-mono">-65%</td>
                <td class="px-4 py-3 text-sm font-mono">+8%</td>
                <td class="px-4 py-3 text-sm font-mono font-medium">8.1x</td>
              </tr>
              <tr>
                <td class="px-4 py-3 text-sm">Adaptive</td>
                <td class="px-4 py-3 text-sm font-mono">-70%</td>
                <td class="px-4 py-3 text-sm font-mono">+12%</td>
                <td class="px-4 py-3 text-sm font-mono">5.8x</td>
              </tr>
              <tr>
                <td class="px-4 py-3 text-sm">Workload-Aware</td>
                <td class="px-4 py-3 text-sm font-mono">-75%</td>
                <td class="px-4 py-3 text-sm font-mono">+10%</td>
                <td class="px-4 py-3 text-sm font-mono">7.5x</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end
end
