defmodule CrucibleUI.Experiments do
  @moduledoc """
  The Experiments context - manages experiments CRUD operations.
  """

  import Ecto.Query, warn: false
  alias CrucibleUI.Repo
  alias CrucibleUI.Experiments.Experiment
  alias Phoenix.PubSub

  @doc """
  Returns the list of experiments.

  ## Examples

      iex> list_experiments()
      [%Experiment{}, ...]

  """
  @spec list_experiments() :: [Experiment.t()]
  def list_experiments do
    Experiment
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns experiments filtered by status.
  """
  @spec list_experiments_by_status(String.t()) :: [Experiment.t()]
  def list_experiments_by_status(status) do
    Experiment
    |> where([e], e.status == ^status)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single experiment.

  Raises `Ecto.NoResultsError` if the Experiment does not exist.

  ## Examples

      iex> get_experiment!(123)
      %Experiment{}

      iex> get_experiment!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_experiment!(integer()) :: Experiment.t()
  def get_experiment!(id), do: Repo.get!(Experiment, id)

  @doc """
  Gets a single experiment with preloaded associations.
  """
  @spec get_experiment_with_runs!(integer()) :: Experiment.t()
  def get_experiment_with_runs!(id) do
    Experiment
    |> Repo.get!(id)
    |> Repo.preload([:runs, :statistical_results])
  end

  @doc """
  Creates a experiment.

  ## Examples

      iex> create_experiment(%{field: value})
      {:ok, %Experiment{}}

      iex> create_experiment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_experiment(map()) :: {:ok, Experiment.t()} | {:error, Ecto.Changeset.t()}
  def create_experiment(attrs \\ %{}) do
    %Experiment{}
    |> Experiment.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:experiment_created)
  end

  @doc """
  Updates a experiment.

  ## Examples

      iex> update_experiment(experiment, %{field: new_value})
      {:ok, %Experiment{}}

      iex> update_experiment(experiment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_experiment(Experiment.t(), map()) ::
          {:ok, Experiment.t()} | {:error, Ecto.Changeset.t()}
  def update_experiment(%Experiment{} = experiment, attrs) do
    experiment
    |> Experiment.changeset(attrs)
    |> Repo.update()
    |> broadcast(:experiment_updated)
  end

  @doc """
  Deletes a experiment.

  ## Examples

      iex> delete_experiment(experiment)
      {:ok, %Experiment{}}

      iex> delete_experiment(experiment)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_experiment(Experiment.t()) :: {:ok, Experiment.t()} | {:error, Ecto.Changeset.t()}
  def delete_experiment(%Experiment{} = experiment) do
    Repo.delete(experiment)
    |> broadcast(:experiment_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking experiment changes.

  ## Examples

      iex> change_experiment(experiment)
      %Ecto.Changeset{data: %Experiment{}}

  """
  @spec change_experiment(Experiment.t(), map()) :: Ecto.Changeset.t()
  def change_experiment(%Experiment{} = experiment, attrs \\ %{}) do
    Experiment.changeset(experiment, attrs)
  end

  @doc """
  Starts an experiment by setting status to running.
  """
  @spec start_experiment(Experiment.t()) :: {:ok, Experiment.t()} | {:error, Ecto.Changeset.t()}
  def start_experiment(%Experiment{} = experiment) do
    update_experiment(experiment, %{status: "running", started_at: DateTime.utc_now()})
  end

  @doc """
  Completes an experiment.
  """
  @spec complete_experiment(Experiment.t()) ::
          {:ok, Experiment.t()} | {:error, Ecto.Changeset.t()}
  def complete_experiment(%Experiment{} = experiment) do
    update_experiment(experiment, %{status: "completed", completed_at: DateTime.utc_now()})
  end

  @doc """
  Fails an experiment.
  """
  @spec fail_experiment(Experiment.t()) :: {:ok, Experiment.t()} | {:error, Ecto.Changeset.t()}
  def fail_experiment(%Experiment{} = experiment) do
    update_experiment(experiment, %{status: "failed", completed_at: DateTime.utc_now()})
  end

  # PubSub broadcasting
  defp broadcast({:ok, experiment}, event) do
    PubSub.broadcast(CrucibleUI.PubSub, "experiments:list", {event, experiment})
    PubSub.broadcast(CrucibleUI.PubSub, "experiment:#{experiment.id}", {event, experiment})
    {:ok, experiment}
  end

  defp broadcast({:error, _} = error, _event), do: error
end
