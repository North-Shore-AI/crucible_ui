defmodule CrucibleUIWeb.ExperimentLive.FormComponent do
  @moduledoc """
  Form component for creating/editing experiments.
  """
  use CrucibleUIWeb, :live_component

  alias CrucibleUI.Experiments

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage experiment records.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="experiment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          options={[
            {"Pending", "pending"},
            {"Running", "running"},
            {"Completed", "completed"},
            {"Failed", "failed"},
            {"Cancelled", "cancelled"}
          ]}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Experiment</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{experiment: experiment} = assigns, socket) do
    changeset = Experiments.change_experiment(experiment)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"experiment" => experiment_params}, socket) do
    changeset =
      socket.assigns.experiment
      |> Experiments.change_experiment(experiment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"experiment" => experiment_params}, socket) do
    save_experiment(socket, socket.assigns.action, experiment_params)
  end

  defp save_experiment(socket, :edit, experiment_params) do
    case Experiments.update_experiment(socket.assigns.experiment, experiment_params) do
      {:ok, _experiment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Experiment updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_experiment(socket, :new, experiment_params) do
    case Experiments.create_experiment(experiment_params) do
      {:ok, _experiment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Experiment created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
