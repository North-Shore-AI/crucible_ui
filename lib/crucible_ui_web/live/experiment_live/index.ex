defmodule CrucibleUIWeb.ExperimentLive.Index do
  @moduledoc """
  LiveView for listing and managing experiments.
  """
  use CrucibleUIWeb, :live_view

  alias CrucibleUI.Experiments
  alias CrucibleUI.Experiments.Experiment

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CrucibleUI.PubSub, "experiments:list")
    end

    {:ok, stream(socket, :experiments, Experiments.list_experiments())}
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
    |> assign(:experiment, %Experiment{})
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
    experiment = Experiments.get_experiment!(id)
    {:ok, _} = Experiments.delete_experiment(experiment)

    {:noreply, stream_delete(socket, :experiments, experiment)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Experiments
        <:actions>
          <.link patch={~p"/experiments/new"}>
            <.button>New Experiment</.button>
          </.link>
        </:actions>
      </.header>

      <.table
        id="experiments"
        rows={@streams.experiments}
        row_click={fn {_id, experiment} -> JS.navigate(~p"/experiments/#{experiment}") end}
      >
        <:col :let={{_id, experiment}} label="Name"><%= experiment.name %></:col>
        <:col :let={{_id, experiment}} label="Status">
          <span class={[
            "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
            status_color(experiment.status)
          ]}>
            <%= experiment.status %>
          </span>
        </:col>
        <:col :let={{_id, experiment}} label="Created">
          <%= Calendar.strftime(experiment.inserted_at, "%Y-%m-%d %H:%M") %>
        </:col>
        <:action :let={{_id, experiment}}>
          <.link navigate={~p"/experiments/#{experiment}"}>Show</.link>
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
        on_cancel={JS.patch(~p"/experiments")}
      >
        <.live_component
          module={CrucibleUIWeb.ExperimentLive.FormComponent}
          id={:new}
          title={@page_title}
          action={@live_action}
          experiment={@experiment}
          patch={~p"/experiments"}
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
