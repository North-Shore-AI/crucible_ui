defmodule CrucibleUIWeb.API.ExperimentJSON do
  @moduledoc """
  JSON rendering for experiments.
  """
  alias CrucibleUI.Experiments.Experiment

  @doc """
  Renders a list of experiments.
  """
  def index(%{experiments: experiments}) do
    %{data: for(experiment <- experiments, do: data(experiment))}
  end

  @doc """
  Renders a single experiment.
  """
  def show(%{experiment: experiment}) do
    %{data: data(experiment)}
  end

  defp data(%Experiment{} = experiment) do
    %{
      id: experiment.id,
      name: experiment.name,
      description: experiment.description,
      status: experiment.status,
      config: experiment.config,
      started_at: experiment.started_at,
      completed_at: experiment.completed_at,
      inserted_at: experiment.inserted_at,
      updated_at: experiment.updated_at
    }
  end
end
