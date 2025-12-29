defmodule Crucible.UI.Backend do
  @moduledoc """
  Behaviour defining the backend interface for Crucible UI feature module.

  Host applications must implement this behaviour to provide data operations
  for the Crucible UI components. This allows the UI to remain independent
  of specific database implementations, Ecto repos, or business logic.

  ## Example Implementation

      defmodule MyApp.CrucibleBackend do
        @behaviour Crucible.UI.Backend

        def list_experiments(opts \\\\ []) do
          experiments = MyApp.Experiments.list_experiments()
          {:ok, experiments}
        end

        def get_experiment(id) do
          case MyApp.Experiments.get_experiment(id) do
            nil -> {:error, :not_found}
            experiment -> {:ok, experiment}
          end
        end

        # ... implement other callbacks
      end

  ## Usage in Router

      experiment_routes "/experiments",
        backend: MyApp.CrucibleBackend,
        root_layout: {MyAppWeb.Layouts, :app}
  """

  @type experiment :: map() | struct()
  @type run :: map() | struct()
  @type telemetry_event :: map() | struct()
  @type statistics :: map() | struct()
  @type opts :: keyword()
  @type id :: term()
  @type error :: term()

  @doc """
  Lists all experiments.

  Backend implementations should return experiments as either Ecto structs or
  plain maps. The UI components handle both transparently.

  ## Options

    * `:status` - Filter by status (e.g., "pending", "running", "completed")
    * `:limit` - Limit number of results
    * `:order` - Order by field (default: `:inserted_at`)

  ## Returns

    * `{:ok, [experiment()]}` - List of experiments
    * `{:error, term()}` - Error tuple
  """
  @callback list_experiments(opts :: opts()) :: {:ok, [experiment()]} | {:error, term()}

  @doc """
  Gets a single experiment by ID.

  ## Returns

    * `{:ok, experiment()}` - The experiment
    * `{:error, :not_found}` - Experiment not found
    * `{:error, term()}` - Other error
  """
  @callback get_experiment(id :: id()) :: {:ok, experiment()} | {:error, term()}

  @doc """
  Gets a single experiment with preloaded associations (runs, results).

  ## Returns

    * `{:ok, experiment()}` - The experiment with associations
    * `{:error, :not_found}` - Experiment not found
    * `{:error, term()}` - Other error
  """
  @callback get_experiment_with_associations(id :: id()) ::
              {:ok, experiment()} | {:error, term()}

  @doc """
  Creates a new experiment.

  ## Parameters

    * `attrs` - Attributes for the new experiment (name, description, config, etc.)

  ## Returns

    * `{:ok, experiment()}` - The created experiment
    * `{:error, changeset()}` - Validation errors
  """
  @callback create_experiment(attrs :: map()) :: {:ok, experiment()} | {:error, term()}

  @doc """
  Updates an experiment.

  ## Parameters

    * `id` - Experiment ID
    * `attrs` - Attributes to update

  ## Returns

    * `{:ok, experiment()}` - The updated experiment
    * `{:error, changeset()}` - Validation errors
  """
  @callback update_experiment(id :: id(), attrs :: map()) ::
              {:ok, experiment()} | {:error, term()}

  @doc """
  Deletes an experiment.

  ## Returns

    * `{:ok, experiment()}` - The deleted experiment
    * `{:error, term()}` - Error tuple
  """
  @callback delete_experiment(id :: id()) :: {:ok, experiment()} | {:error, term()}

  @doc """
  Starts an experiment (updates status to "running").

  ## Returns

    * `{:ok, experiment()}` - The updated experiment
    * `{:error, term()}` - Error tuple
  """
  @callback start_experiment(id :: id()) :: {:ok, experiment()} | {:error, term()}

  @doc """
  Completes an experiment (updates status to "completed").

  ## Returns

    * `{:ok, experiment()}` - The updated experiment
    * `{:error, term()}` - Error tuple
  """
  @callback complete_experiment(id :: id()) :: {:ok, experiment()} | {:error, term()}

  @doc """
  Lists runs for an experiment.

  ## Options

    * `:status` - Filter by status
    * `:limit` - Limit number of results

  ## Returns

    * `{:ok, [run()]}` - List of runs
    * `{:error, term()}` - Error tuple
  """
  @callback list_runs(experiment_id :: id(), opts :: opts()) ::
              {:ok, [run()]} | {:error, term()}

  @doc """
  Gets a single run by ID with associations (experiment, events).

  ## Returns

    * `{:ok, run()}` - The run with associations
    * `{:error, :not_found}` - Run not found
    * `{:error, term()}` - Other error
  """
  @callback get_run(id :: id()) :: {:ok, run()} | {:error, term()}

  @doc """
  Starts a run (updates status to "running").

  ## Returns

    * `{:ok, run()}` - The updated run
    * `{:error, term()}` - Error tuple
  """
  @callback start_run(id :: id()) :: {:ok, run()} | {:error, term()}

  @doc """
  Completes a run (updates status to "completed").

  ## Returns

    * `{:ok, run()}` - The updated run
    * `{:error, term()}` - Error tuple
  """
  @callback complete_run(id :: id()) :: {:ok, run()} | {:error, term()}

  @doc """
  Lists telemetry events for a run.

  ## Options

    * `:limit` - Limit number of results (default: 100)
    * `:event_type` - Filter by event type

  ## Returns

    * `{:ok, [telemetry_event()]}` - List of events
    * `{:error, term()}` - Error tuple
  """
  @callback list_telemetry_events(run_id :: id(), opts :: opts()) ::
              {:ok, [telemetry_event()]} | {:error, term()}

  @doc """
  Gets statistics for an experiment or run.

  ## Returns

    * `{:ok, statistics()}` - Statistics data
    * `{:error, term()}` - Error tuple
  """
  @callback get_statistics(id :: id()) :: {:ok, statistics()} | {:error, term()}

  @doc """
  Gets aggregated statistics for the system (total experiments, runs, etc.).

  ## Returns

    * `{:ok, map()}` - Aggregated statistics
  """
  @callback get_system_statistics() :: {:ok, map()} | {:error, term()}

  @doc """
  Optional callback for custom PubSub topic for experiment updates.

  If not implemented, defaults to "experiment:{id}".

  ## Returns

    * `String.t()` - PubSub topic name
  """
  @callback pubsub_topic(resource :: atom(), id :: id()) :: String.t()

  @optional_callbacks pubsub_topic: 2
end
