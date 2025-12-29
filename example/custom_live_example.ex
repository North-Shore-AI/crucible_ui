defmodule Example.CustomLive do
  @moduledoc """
  Examples of using Crucible UI components in custom LiveViews.

  These examples show how to integrate Crucible UI components into your
  own Phoenix LiveViews for consistent styling and functionality.
  """

  # Example 1: Custom dashboard with stat cards
  defmodule DashboardExample do
    use Phoenix.LiveView
    import Crucible.UI.Components

    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:experiment_count, 42)
       |> assign(:running_count, 5)
       |> assign(:completed_count, 37)
       |> assign(:avg_accuracy, 0.89)}
    end

    def render(assigns) do
      ~H"""
      <div class="space-y-8">
        <.header>
          ML Research Dashboard
          <:subtitle>Real-time experiment tracking and analytics</:subtitle>
          <:actions>
            <.button phx-click="sync">Sync Data</.button>
            <.button phx-click="export">Export Report</.button>
          </:actions>
        </.header>

        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          <.stat_card
            icon="hero-beaker"
            label="Total Experiments"
            value={@experiment_count}
            icon_class="text-gray-400"
          />

          <.stat_card
            icon="hero-play"
            label="Running"
            value={@running_count}
            icon_class="text-green-400"
          />

          <.stat_card
            icon="hero-check-circle"
            label="Completed"
            value={@completed_count}
            icon_class="text-blue-400"
          />

          <.stat_card
            icon="hero-chart-bar"
            label="Avg Accuracy"
            value={"#{round(@avg_accuracy * 100)}%"}
            icon_class="text-emerald-400"
          />
        </div>
      </div>
      """
    end
  end

  # Example 2: Experiment list with table
  defmodule ExperimentListExample do
    use Phoenix.LiveView
    import Crucible.UI.Components
    alias Phoenix.LiveView.JS

    def mount(_params, _session, socket) do
      experiments = [
        %{id: 1, name: "Baseline Model", status: "completed", accuracy: 0.85},
        %{id: 2, name: "Fine-tuned v1", status: "running", accuracy: 0.91},
        %{id: 3, name: "Fine-tuned v2", status: "pending", accuracy: nil}
      ]

      {:ok, stream(socket, :experiments, experiments)}
    end

    def render(assigns) do
      ~H"""
      <div class="space-y-6">
        <.header>
          My Experiments
          <:actions>
            <.link navigate="/experiments/new">
              <.button>New Experiment</.button>
            </.link>
          </:actions>
        </.header>

        <.table
          id="experiments"
          rows={@streams.experiments}
          row_click={fn {_id, exp} -> JS.navigate("/experiments/#{exp.id}") end}
        >
          <:col :let={{_id, exp}} label="Name">
            <%= exp.name %>
          </:col>

          <:col :let={{_id, exp}} label="Status">
            <.status_badge status={exp.status} />
          </:col>

          <:col :let={{_id, exp}} label="Accuracy">
            <%= if exp.accuracy, do: "#{round(exp.accuracy * 100)}%", else: "N/A" %>
          </:col>

          <:action :let={{_id, exp}}>
            <.link navigate={"/experiments/#{exp.id}"}>View</.link>
          </:action>

          <:action :let={{id, exp}}>
            <.link
              phx-click={JS.push("delete", value: %{id: exp.id}) |> JS.hide(to: "##{id}")}
              data-confirm="Are you sure?"
            >
              Delete
            </.link>
          </:action>
        </.table>
      </div>
      """
    end
  end

  # Example 3: Experiment details with actions
  defmodule ExperimentDetailsExample do
    use Phoenix.LiveView
    import Crucible.UI.Components

    def mount(%{"id" => id}, _session, socket) do
      experiment = %{
        id: id,
        name: "Baseline Model",
        description: "Initial baseline experiment with default hyperparameters",
        status: "running",
        started_at: ~U[2025-12-06 10:00:00Z],
        completed_at: nil,
        config: %{
          model: "llama-3.1-8b",
          epochs: 3,
          learning_rate: 0.0001
        }
      }

      {:ok, assign(socket, :experiment, experiment)}
    end

    def render(assigns) do
      ~H"""
      <div class="space-y-6">
        <.header>
          <%= @experiment.name %>
          <:subtitle><%= @experiment.description %></:subtitle>
          <:actions>
            <.button phx-click="pause">Pause</.button>
            <.button phx-click="stop">Stop</.button>
          </:actions>
        </.header>

        <.list>
          <:item title="Status">
            <.status_badge status={@experiment.status} />
          </:item>

          <:item title="Started">
            <%= Calendar.strftime(@experiment.started_at, "%Y-%m-%d %H:%M:%S") %>
          </:item>

          <:item title="Completed">
            <%= @experiment.completed_at || "In progress" %>
          </:item>

          <:item title="Configuration">
            <pre class="text-xs bg-gray-50 p-2 rounded"><%= Jason.encode!(@experiment.config, pretty: true) %></pre>
          </:item>
        </.list>

        <.back navigate="/experiments">Back to experiments</.back>
      </div>
      """
    end
  end

  # Example 4: Modal usage
  defmodule ModalExample do
    use Phoenix.LiveView
    import Crucible.UI.Components
    alias Phoenix.LiveView.JS

    def mount(_params, _session, socket) do
      {:ok, assign(socket, :show_modal, false)}
    end

    def handle_event("open_modal", _, socket) do
      {:noreply, assign(socket, :show_modal, true)}
    end

    def handle_event("close_modal", _, socket) do
      {:noreply, assign(socket, :show_modal, false)}
    end

    def render(assigns) do
      ~H"""
      <div>
        <.button phx-click="open_modal">Open Modal</.button>

        <.modal id="confirm-modal" show={@show_modal} on_cancel={JS.push("close_modal")}>
          <div class="space-y-4">
            <h2 class="text-xl font-semibold">Confirm Action</h2>
            <p class="text-gray-600">
              Are you sure you want to delete this experiment?
              This action cannot be undone.
            </p>
            <div class="flex gap-4 justify-end">
              <.button phx-click="close_modal">Cancel</.button>
              <.button phx-click="confirm_delete" class="bg-red-600 hover:bg-red-700">
                Delete
              </.button>
            </div>
          </div>
        </.modal>
      </div>
      """
    end
  end

  # Example 5: Combining multiple components
  defmodule CombinedExample do
    use Phoenix.LiveView
    import Crucible.UI.Components

    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:total_runs, 156)
       |> assign(:active_runs, 12)
       |> assign(:recent_runs, [
         %{id: 1, name: "Run #101", status: "running"},
         %{id: 2, name: "Run #102", status: "completed"},
         %{id: 3, name: "Run #103", status: "failed"}
       ])}
    end

    def render(assigns) do
      ~H"""
      <div class="space-y-8">
        <.header>
          Run Monitor
          <:subtitle>Real-time monitoring of experiment runs</:subtitle>
        </.header>

        <div class="grid grid-cols-2 gap-4">
          <.stat_card icon="hero-chart-bar" label="Total Runs" value={@total_runs} />
          <.stat_card icon="hero-play" label="Active" value={@active_runs} icon_class="text-green-400" />
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Recent Runs</h3>
          <div class="space-y-3">
            <%= for run <- @recent_runs do %>
              <div class="flex justify-between items-center p-3 border rounded hover:bg-gray-50">
                <div class="flex items-center gap-3">
                  <.icon name="hero-play" class="h-5 w-5 text-gray-400" />
                  <span class="font-medium"><%= run.name %></span>
                </div>
                <.status_badge status={run.status} />
              </div>
            <% end %>
          </div>
        </div>

        <.back navigate="/">Back to dashboard</.back>
      </div>
      """
    end
  end
end
