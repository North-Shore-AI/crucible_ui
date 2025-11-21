defmodule CrucibleUIWeb.API.ExperimentController do
  @moduledoc """
  REST API controller for experiments.
  """
  use CrucibleUIWeb, :controller

  alias CrucibleUI.Experiments
  alias CrucibleUI.Experiments.Experiment

  action_fallback CrucibleUIWeb.FallbackController

  @doc """
  List all experiments.
  """
  def index(conn, _params) do
    experiments = Experiments.list_experiments()
    render(conn, :index, experiments: experiments)
  end

  @doc """
  Create a new experiment.
  """
  def create(conn, %{"experiment" => experiment_params}) do
    with {:ok, %Experiment{} = experiment} <- Experiments.create_experiment(experiment_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/experiments/#{experiment}")
      |> render(:show, experiment: experiment)
    end
  end

  @doc """
  Show a single experiment.
  """
  def show(conn, %{"id" => id}) do
    experiment = Experiments.get_experiment!(id)
    render(conn, :show, experiment: experiment)
  end

  @doc """
  Update an experiment.
  """
  def update(conn, %{"id" => id, "experiment" => experiment_params}) do
    experiment = Experiments.get_experiment!(id)

    with {:ok, %Experiment{} = experiment} <-
           Experiments.update_experiment(experiment, experiment_params) do
      render(conn, :show, experiment: experiment)
    end
  end

  @doc """
  Delete an experiment.
  """
  def delete(conn, %{"id" => id}) do
    experiment = Experiments.get_experiment!(id)

    with {:ok, %Experiment{}} <- Experiments.delete_experiment(experiment) do
      send_resp(conn, :no_content, "")
    end
  end
end
