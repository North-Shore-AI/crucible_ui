defmodule CrucibleUI.DefaultBackend do
  @moduledoc """
  Default backend implementation for Crucible UI using existing contexts.

  This adapter allows the existing CrucibleUI app to work with the new
  composable architecture without breaking changes. It wraps the existing
  `CrucibleUI.Experiments`, `CrucibleUI.Runs`, and `CrucibleUI.Telemetry`
  contexts to conform to the `Crucible.UI.Backend` behaviour.

  ## Usage

      # In your router
      import Crucible.UI.Router

      experiment_routes "/",
        backend: CrucibleUI.DefaultBackend,
        root_layout: {CrucibleUIWeb.Layouts, :root},
        pubsub: CrucibleUI.PubSub

  ## PubSub Topics

  This backend defines the following PubSub topics:
  - `experiments:list` - All experiment updates
  - `runs:list` - All run updates
  - `experiment:{id}` - Specific experiment updates
  - `experiment:{id}:runs` - Run updates for an experiment
  - `run:{id}` - Specific run updates
  - `run:{id}:telemetry` - Telemetry events for a run
  """

  @behaviour Crucible.UI.Backend

  alias CrucibleUI.{Experiments, Runs, Statistics, Telemetry}

  @impl true
  @spec list_experiments(keyword()) :: {:ok, [Experiments.Experiment.t()]}
  def list_experiments(opts \\ []) do
    experiments =
      case Keyword.get(opts, :status) do
        nil -> Experiments.list_experiments()
        status -> Experiments.list_experiments_by_status(status)
      end

    {:ok, experiments}
  end

  @impl true
  @spec get_experiment(term()) :: {:ok, Experiments.Experiment.t()} | {:error, :not_found}
  def get_experiment(id) do
    experiment = Experiments.get_experiment!(id)
    {:ok, experiment}
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  @impl true
  @spec get_experiment_with_associations(term()) ::
          {:ok, Experiments.Experiment.t()} | {:error, :not_found}
  def get_experiment_with_associations(id) do
    experiment = Experiments.get_experiment_with_runs!(id)
    {:ok, experiment}
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  @impl true
  @spec create_experiment(map()) ::
          {:ok, Experiments.Experiment.t()} | {:error, Ecto.Changeset.t()}
  def create_experiment(attrs) do
    Experiments.create_experiment(attrs)
  end

  @impl true
  @spec update_experiment(term(), map()) ::
          {:ok, Experiments.Experiment.t()} | {:error, Ecto.Changeset.t() | :not_found}
  def update_experiment(id, attrs) do
    experiment = Experiments.get_experiment!(id)
    Experiments.update_experiment(experiment, attrs)
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  @impl true
  @spec delete_experiment(term()) ::
          {:ok, Experiments.Experiment.t()} | {:error, Ecto.Changeset.t() | :not_found}
  def delete_experiment(id) do
    experiment = Experiments.get_experiment!(id)
    Experiments.delete_experiment(experiment)
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  @impl true
  @spec start_experiment(term()) ::
          {:ok, Experiments.Experiment.t()} | {:error, Ecto.Changeset.t() | :not_found}
  def start_experiment(id) do
    experiment = Experiments.get_experiment!(id)
    Experiments.start_experiment(experiment)
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  @impl true
  @spec complete_experiment(term()) ::
          {:ok, Experiments.Experiment.t()} | {:error, Ecto.Changeset.t() | :not_found}
  def complete_experiment(id) do
    experiment = Experiments.get_experiment!(id)
    Experiments.complete_experiment(experiment)
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  @impl true
  @spec list_runs(term(), keyword()) :: {:ok, [Runs.Run.t()]}
  def list_runs(experiment_id, _opts \\ []) do
    runs = Runs.list_runs_for_experiment(experiment_id)
    {:ok, runs}
  rescue
    _ -> {:ok, []}
  end

  @impl true
  @spec get_run(term()) :: {:ok, Runs.Run.t()} | {:error, :not_found}
  def get_run(id) do
    run = Runs.get_run_with_events!(id)
    {:ok, run}
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  @impl true
  @spec start_run(term()) :: {:ok, Runs.Run.t()} | {:error, Ecto.Changeset.t() | :not_found}
  def start_run(id) do
    run = Runs.get_run!(id)
    Runs.start_run(run)
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  @impl true
  @spec complete_run(term()) :: {:ok, Runs.Run.t()} | {:error, Ecto.Changeset.t() | :not_found}
  def complete_run(id) do
    run = Runs.get_run!(id)
    Runs.complete_run(run)
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  @impl true
  @spec list_telemetry_events(term(), keyword()) :: {:ok, [Telemetry.Event.t()]}
  def list_telemetry_events(run_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    events = Telemetry.list_events_for_run(run_id) |> Enum.take(limit)
    {:ok, events}
  rescue
    _ -> {:ok, []}
  end

  @impl true
  @spec get_statistics(term()) :: {:ok, map()}
  def get_statistics(_id) do
    # Placeholder - implement based on your statistics requirements
    {:ok, %{}}
  end

  @impl true
  @spec get_system_statistics() :: {:ok, map()}
  def get_system_statistics do
    experiments = Experiments.list_experiments()
    runs = Runs.list_runs()
    results = Statistics.list_results()

    running_experiments = Enum.count(experiments, &(&1.status == "running"))
    completed_experiments = Enum.count(experiments, &(&1.status == "completed"))
    running_runs = Enum.count(runs, &(&1.status == "running"))
    significant_results = Enum.count(results, &(&1.p_value && &1.p_value < 0.05))

    {:ok,
     %{
       total_experiments: length(experiments),
       running_experiments: running_experiments,
       completed_experiments: completed_experiments,
       total_runs: length(runs),
       running_runs: running_runs,
       significant_results: significant_results,
       recent_experiments: Enum.take(experiments, 5),
       recent_runs: Enum.take(runs, 5)
     }}
  rescue
    _ ->
      {:ok,
       %{
         total_experiments: 0,
         running_experiments: 0,
         completed_experiments: 0,
         total_runs: 0,
         running_runs: 0,
         significant_results: 0,
         recent_experiments: [],
         recent_runs: []
       }}
  end

  @impl true
  @spec pubsub_topic(atom(), term()) :: String.t()
  def pubsub_topic(:experiments_list, _id), do: "experiments:list"
  def pubsub_topic(:runs_list, _id), do: "runs:list"
  def pubsub_topic(:experiment, id), do: "experiment:#{id}"
  def pubsub_topic(:experiment_runs, id), do: "experiment:#{id}:runs"
  def pubsub_topic(:run, id), do: "run:#{id}"
  def pubsub_topic(:run_telemetry, id), do: "run:#{id}:telemetry"
  def pubsub_topic(_, _), do: "crucible:updates"
end
