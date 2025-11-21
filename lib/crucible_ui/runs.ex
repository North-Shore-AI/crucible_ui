defmodule CrucibleUI.Runs do
  @moduledoc """
  The Runs context - manages experiment runs.
  """

  import Ecto.Query, warn: false
  alias CrucibleUI.Repo
  alias CrucibleUI.Runs.Run
  alias Phoenix.PubSub

  @doc """
  Returns the list of runs.
  """
  @spec list_runs() :: [Run.t()]
  def list_runs do
    Run
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns runs for a specific experiment.
  """
  @spec list_runs_for_experiment(integer()) :: [Run.t()]
  def list_runs_for_experiment(experiment_id) do
    Run
    |> where([r], r.experiment_id == ^experiment_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns runs filtered by status.
  """
  @spec list_runs_by_status(String.t()) :: [Run.t()]
  def list_runs_by_status(status) do
    Run
    |> where([r], r.status == ^status)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single run.

  Raises `Ecto.NoResultsError` if the Run does not exist.
  """
  @spec get_run!(integer()) :: Run.t()
  def get_run!(id), do: Repo.get!(Run, id)

  @doc """
  Gets a run with preloaded associations.
  """
  @spec get_run_with_events!(integer()) :: Run.t()
  def get_run_with_events!(id) do
    Run
    |> Repo.get!(id)
    |> Repo.preload([:experiment, :telemetry_events, :statistical_results])
  end

  @doc """
  Creates a run.
  """
  @spec create_run(map()) :: {:ok, Run.t()} | {:error, Ecto.Changeset.t()}
  def create_run(attrs \\ %{}) do
    %Run{}
    |> Run.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:run_created)
  end

  @doc """
  Updates a run.
  """
  @spec update_run(Run.t(), map()) :: {:ok, Run.t()} | {:error, Ecto.Changeset.t()}
  def update_run(%Run{} = run, attrs) do
    run
    |> Run.changeset(attrs)
    |> Repo.update()
    |> broadcast(:run_updated)
  end

  @doc """
  Deletes a run.
  """
  @spec delete_run(Run.t()) :: {:ok, Run.t()} | {:error, Ecto.Changeset.t()}
  def delete_run(%Run{} = run) do
    Repo.delete(run)
    |> broadcast(:run_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking run changes.
  """
  @spec change_run(Run.t(), map()) :: Ecto.Changeset.t()
  def change_run(%Run{} = run, attrs \\ %{}) do
    Run.changeset(run, attrs)
  end

  @doc """
  Starts a run.
  """
  @spec start_run(Run.t()) :: {:ok, Run.t()} | {:error, Ecto.Changeset.t()}
  def start_run(%Run{} = run) do
    update_run(run, %{status: "running", started_at: DateTime.utc_now()})
  end

  @doc """
  Completes a run with metrics.
  """
  @spec complete_run(Run.t(), map()) :: {:ok, Run.t()} | {:error, Ecto.Changeset.t()}
  def complete_run(%Run{} = run, metrics \\ %{}) do
    update_run(run, %{
      status: "completed",
      completed_at: DateTime.utc_now(),
      metrics: Map.merge(run.metrics || %{}, metrics)
    })
  end

  @doc """
  Fails a run.
  """
  @spec fail_run(Run.t()) :: {:ok, Run.t()} | {:error, Ecto.Changeset.t()}
  def fail_run(%Run{} = run) do
    update_run(run, %{status: "failed", completed_at: DateTime.utc_now()})
  end

  # PubSub broadcasting
  defp broadcast({:ok, run}, event) do
    PubSub.broadcast(CrucibleUI.PubSub, "runs:list", {event, run})
    PubSub.broadcast(CrucibleUI.PubSub, "run:#{run.id}", {event, run})
    PubSub.broadcast(CrucibleUI.PubSub, "experiment:#{run.experiment_id}:runs", {event, run})
    {:ok, run}
  end

  defp broadcast({:error, _} = error, _event), do: error
end
