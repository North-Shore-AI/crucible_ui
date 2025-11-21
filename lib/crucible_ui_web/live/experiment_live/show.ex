defmodule CrucibleUIWeb.ExperimentLive.Show do
  @moduledoc """
  LiveView for showing experiment details.
  """
  use CrucibleUIWeb, :live_view

  alias CrucibleUI.Experiments

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CrucibleUI.PubSub, "experiment:#{id}")
      Phoenix.PubSub.subscribe(CrucibleUI.PubSub, "experiment:#{id}:runs")
    end

    experiment = Experiments.get_experiment_with_runs!(id)

    {:ok,
     socket
     |> assign(:experiment, experiment)
     |> assign(:runs, experiment.runs)
     |> assign(:results, experiment.statistical_results)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, socket.assigns.experiment.name)
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Edit #{socket.assigns.experiment.name}")
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
        if r.id == run.id, do: run, else: r
      end)

    {:noreply, assign(socket, :runs, runs)}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def handle_event("start", _params, socket) do
    {:ok, experiment} = Experiments.start_experiment(socket.assigns.experiment)
    {:noreply, assign(socket, :experiment, experiment)}
  end

  @impl true
  def handle_event("complete", _params, socket) do
    {:ok, experiment} = Experiments.complete_experiment(socket.assigns.experiment)
    {:noreply, assign(socket, :experiment, experiment)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @experiment.name %>
        <:subtitle><%= @experiment.description %></:subtitle>
        <:actions>
          <.link patch={~p"/experiments/#{@experiment}/edit"} phx-click={JS.push_focus()}>
            <.button>Edit</.button>
          </.link>
        </:actions>
      </.header>

      <.list>
        <:item title="Status">
          <span class={[
            "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
            status_color(@experiment.status)
          ]}>
            <%= @experiment.status %>
          </span>
        </:item>
        <:item title="Started"><%= @experiment.started_at || "Not started" %></:item>
        <:item title="Completed"><%= @experiment.completed_at || "Not completed" %></:item>
        <:item title="Configuration">
          <pre class="text-xs bg-gray-50 p-2 rounded"><%= Jason.encode!(@experiment.config, pretty: true) %></pre>
        </:item>
      </.list>

      <div class="mt-8 flex gap-4">
        <.button :if={@experiment.status == "pending"} phx-click="start">Start Experiment</.button>
        <.button :if={@experiment.status == "running"} phx-click="complete">Complete</.button>
      </div>

      <div class="mt-8">
        <h3 class="text-lg font-semibold">Runs (<%= length(@runs) %>)</h3>
        <div class="mt-4 space-y-2">
          <%= for run <- @runs do %>
            <div class="border rounded p-3">
              <div class="flex justify-between items-center">
                <.link navigate={~p"/runs/#{run.id}"} class="font-medium hover:text-zinc-700">
                  Run #<%= run.id %>
                </.link>
                <span class={[
                  "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                  status_color(run.status)
                ]}>
                  <%= run.status %>
                </span>
              </div>
            </div>
          <% end %>
          <%= if @runs == [] do %>
            <p class="text-sm text-gray-500">No runs yet</p>
          <% end %>
        </div>
      </div>

      <.back navigate={~p"/experiments"}>Back to experiments</.back>

      <.modal
        :if={@live_action == :edit}
        id="experiment-modal"
        show
        on_cancel={JS.patch(~p"/experiments/#{@experiment}")}
      >
        <.live_component
          module={CrucibleUIWeb.ExperimentLive.FormComponent}
          id={@experiment.id}
          title={@page_title}
          action={@live_action}
          experiment={@experiment}
          patch={~p"/experiments/#{@experiment}"}
        />
      </.modal>
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
