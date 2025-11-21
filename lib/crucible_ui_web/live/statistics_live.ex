defmodule CrucibleUIWeb.StatisticsLive do
  @moduledoc """
  LiveView for statistical test results and visualizations.
  """
  use CrucibleUIWeb, :live_view

  alias CrucibleUI.Statistics

  @impl true
  def mount(_params, _session, socket) do
    results = Statistics.list_results()

    {:ok,
     socket
     |> assign(:results, results)
     |> assign(:filter_type, nil)
     |> assign(:show_significant_only, false)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Statistical Results")
    |> assign(:selected_result, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    result = Statistics.get_result!(id)

    socket
    |> assign(:page_title, "Result: #{result.test_type}")
    |> assign(:selected_result, result)
  end

  @impl true
  def handle_event("filter", %{"type" => type}, socket) do
    results =
      if type == "", do: Statistics.list_results(), else: Statistics.list_results_by_type(type)

    {:noreply, assign(socket, :results, results)}
  end

  @impl true
  def handle_event("toggle_significant", _params, socket) do
    show_significant = !socket.assigns.show_significant_only

    results =
      if show_significant,
        do: Statistics.list_significant_results(),
        else: Statistics.list_results()

    {:noreply,
     socket |> assign(:results, results) |> assign(:show_significant_only, show_significant)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Statistical Results
        <:subtitle>Test results with effect sizes and confidence intervals</:subtitle>
      </.header>

      <div class="mt-6 flex gap-4 items-center">
        <select phx-change="filter" name="type" class="rounded-md border-gray-300 text-sm">
          <option value="">All Types</option>
          <option value="t_test">T-Test</option>
          <option value="anova">ANOVA</option>
          <option value="mann_whitney">Mann-Whitney</option>
          <option value="wilcoxon">Wilcoxon</option>
        </select>

        <label class="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            phx-click="toggle_significant"
            checked={@show_significant_only}
            class="rounded border-gray-300"
          /> Significant only (p &lt; 0.05)
        </label>
      </div>

      <div class="mt-6 grid gap-4">
        <%= for result <- @results do %>
          <div class="bg-white shadow rounded-lg p-4">
            <div class="flex justify-between items-start">
              <div>
                <h3 class="font-semibold"><%= result.test_type %></h3>
                <div class="mt-2 text-sm text-gray-600">
                  <span class="mr-4">
                    p-value: <span class="font-mono"><%= format_p_value(result.p_value) %></span>
                    <span class="ml-1"><%= Statistics.significance_level(result.p_value) %></span>
                  </span>
                  <%= if result.effect_size do %>
                    <span>
                      Effect size:
                      <span class="font-mono"><%= Float.round(result.effect_size, 3) %></span>
                      (<%= Statistics.interpret_effect_size(
                        result.effect_size,
                        result.effect_size_type || "cohens_d"
                      ) %>)
                    </span>
                  <% end %>
                </div>
              </div>
              <span class={[
                "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                if(result.p_value && result.p_value < 0.05,
                  do: "bg-green-100 text-green-800",
                  else: "bg-gray-100 text-gray-800"
                )
              ]}>
                <%= if result.p_value && result.p_value < 0.05,
                  do: "Significant",
                  else: "Not significant" %>
              </span>
            </div>
            <%= if result.confidence_interval != [] do %>
              <div class="mt-2 text-xs text-gray-500">
                95% CI: [<%= Enum.join(
                  Enum.map(result.confidence_interval, &Float.round(&1, 3)),
                  ", "
                ) %>]
              </div>
            <% end %>
          </div>
        <% end %>
        <%= if @results == [] do %>
          <p class="text-sm text-gray-500">No statistical results yet</p>
        <% end %>
      </div>
    </div>
    """
  end

  defp format_p_value(nil), do: "N/A"
  defp format_p_value(p) when p < 0.001, do: "< 0.001"
  defp format_p_value(p), do: Float.round(p, 4)
end
