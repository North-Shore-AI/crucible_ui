defmodule Example.CrucibleBackend do
  @moduledoc """
  Example Backend implementation using in-memory storage (ETS).

  This example demonstrates all 15 required callbacks of the `Crucible.UI.Backend`
  behaviour without requiring a database. Perfect for testing, demos, or simple
  use cases.

  ## Usage

  In your application supervisor:

      children = [
        {Example.CrucibleBackend, name: Example.CrucibleBackend}
      ]

  In your router:

      experiment_routes "/",
        backend: Example.CrucibleBackend,
        pubsub: MyApp.PubSub

  ## Implementation Notes

  - Uses ETS tables for storage
  - Broadcasts PubSub messages for real-time updates
  - Generates sequential IDs
  - Supports all Backend callbacks
  """

  use GenServer
  @behaviour Crucible.UI.Backend

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  @spec list_experiments(keyword()) :: {:ok, [map()]}
  def list_experiments(opts \\ []) do
    experiments = :ets.tab2list(:experiments) |> Enum.map(fn {_id, exp} -> exp end)

    experiments =
      case opts[:status] do
        nil -> experiments
        status -> Enum.filter(experiments, &(&1.status == status))
      end

    experiments =
      case opts[:limit] do
        nil -> experiments
        limit -> Enum.take(experiments, limit)
      end

    {:ok, Enum.sort_by(experiments, & &1.inserted_at, {:desc, DateTime})}
  end

  @impl true
  @spec get_experiment(term()) :: {:ok, map()} | {:error, :not_found}
  def get_experiment(id) do
    case :ets.lookup(:experiments, id) do
      [{^id, experiment}] -> {:ok, experiment}
      [] -> {:error, :not_found}
    end
  end

  @impl true
  @spec get_experiment_with_associations(term()) :: {:ok, map()} | {:error, :not_found}
  def get_experiment_with_associations(id) do
    case get_experiment(id) do
      {:ok, experiment} ->
        {:ok, runs} = list_runs(id, [])
        {:ok, Map.put(experiment, :runs, runs)}

      error ->
        error
    end
  end

  @impl true
  @spec create_experiment(map()) :: {:ok, map()} | {:error, term()}
  def create_experiment(attrs) do
    id = next_id(:experiment_id)
    now = DateTime.utc_now()

    experiment = %{
      id: id,
      name: attrs[:name] || "Experiment #{id}",
      description: attrs[:description],
      status: "pending",
      config: attrs[:config] || %{},
      started_at: nil,
      completed_at: nil,
      inserted_at: now,
      updated_at: now
    }

    :ets.insert(:experiments, {id, experiment})
    broadcast({:experiment_created, experiment})
    {:ok, experiment}
  end

  @impl true
  @spec update_experiment(term(), map()) :: {:ok, map()} | {:error, :not_found}
  def update_experiment(id, attrs) do
    case get_experiment(id) do
      {:ok, experiment} ->
        experiment =
          experiment
          |> Map.merge(Map.take(attrs, [:name, :description, :config, :status]))
          |> Map.put(:updated_at, DateTime.utc_now())

        :ets.insert(:experiments, {id, experiment})
        broadcast({:experiment_updated, experiment})
        {:ok, experiment}

      error ->
        error
    end
  end

  @impl true
  @spec delete_experiment(term()) :: {:ok, map()} | {:error, :not_found}
  def delete_experiment(id) do
    case get_experiment(id) do
      {:ok, experiment} ->
        :ets.delete(:experiments, id)
        broadcast({:experiment_deleted, experiment})
        {:ok, experiment}

      error ->
        error
    end
  end

  @impl true
  @spec start_experiment(term()) :: {:ok, map()} | {:error, :not_found}
  def start_experiment(id) do
    update_experiment(id, %{status: "running", started_at: DateTime.utc_now()})
  end

  @impl true
  @spec complete_experiment(term()) :: {:ok, map()} | {:error, :not_found}
  def complete_experiment(id) do
    update_experiment(id, %{status: "completed", completed_at: DateTime.utc_now()})
  end

  @impl true
  @spec list_runs(term(), keyword()) :: {:ok, [map()]}
  def list_runs(experiment_id, opts \\ []) do
    runs =
      :ets.tab2list(:runs)
      |> Enum.map(fn {_id, run} -> run end)
      |> Enum.filter(&(&1.experiment_id == experiment_id))

    runs =
      case opts[:status] do
        nil -> runs
        status -> Enum.filter(runs, &(&1.status == status))
      end

    {:ok, Enum.sort_by(runs, & &1.inserted_at, {:desc, DateTime})}
  end

  @impl true
  @spec get_run(term()) :: {:ok, map()} | {:error, :not_found}
  def get_run(id) do
    case :ets.lookup(:runs, id) do
      [{^id, run}] ->
        {:ok, experiment} = get_experiment(run.experiment_id)
        {:ok, events} = list_telemetry_events(id, limit: 100)
        {:ok, Map.merge(run, %{experiment: experiment, telemetry_events: events})}

      [] ->
        {:error, :not_found}
    end
  end

  @impl true
  @spec start_run(term()) :: {:ok, map()} | {:error, :not_found}
  def start_run(id) do
    case :ets.lookup(:runs, id) do
      [{^id, run}] ->
        run =
          run
          |> Map.put(:status, "running")
          |> Map.put(:started_at, DateTime.utc_now())
          |> Map.put(:updated_at, DateTime.utc_now())

        :ets.insert(:runs, {id, run})
        broadcast({:run_updated, run})
        {:ok, run}

      [] ->
        {:error, :not_found}
    end
  end

  @impl true
  @spec complete_run(term()) :: {:ok, map()} | {:error, :not_found}
  def complete_run(id) do
    case :ets.lookup(:runs, id) do
      [{^id, run}] ->
        run =
          run
          |> Map.put(:status, "completed")
          |> Map.put(:completed_at, DateTime.utc_now())
          |> Map.put(:updated_at, DateTime.utc_now())

        :ets.insert(:runs, {id, run})
        broadcast({:run_updated, run})
        {:ok, run}

      [] ->
        {:error, :not_found}
    end
  end

  @impl true
  @spec list_telemetry_events(term(), keyword()) :: {:ok, [map()]}
  def list_telemetry_events(run_id, opts \\ []) do
    limit = opts[:limit] || 100

    events =
      :ets.tab2list(:telemetry_events)
      |> Enum.map(fn {_id, event} -> event end)
      |> Enum.filter(&(&1.run_id == run_id))
      |> Enum.sort_by(& &1.recorded_at, {:desc, DateTime})
      |> Enum.take(limit)

    {:ok, events}
  end

  @impl true
  @spec get_statistics(term()) :: {:ok, map()}
  def get_statistics(_id) do
    {:ok, %{}}
  end

  @impl true
  @spec get_system_statistics() :: {:ok, map()}
  def get_system_statistics do
    {:ok, experiments} = list_experiments([])
    {:ok, all_runs} = GenServer.call(__MODULE__, :list_all_runs)

    {:ok,
     %{
       total_experiments: length(experiments),
       running_experiments: Enum.count(experiments, &(&1.status == "running")),
       completed_experiments: Enum.count(experiments, &(&1.status == "completed")),
       total_runs: length(all_runs),
       running_runs: Enum.count(all_runs, &(&1.status == "running")),
       significant_results: 0,
       recent_experiments: Enum.take(experiments, 5),
       recent_runs: Enum.take(all_runs, 5)
     }}
  end

  @impl true
  @spec pubsub_topic(atom(), term()) :: String.t()
  def pubsub_topic(:experiments_list, _id), do: "example:experiments:list"
  def pubsub_topic(:runs_list, _id), do: "example:runs:list"
  def pubsub_topic(:experiment, id), do: "example:experiment:#{id}"
  def pubsub_topic(:experiment_runs, id), do: "example:experiment:#{id}:runs"
  def pubsub_topic(:run, id), do: "example:run:#{id}"
  def pubsub_topic(:run_telemetry, id), do: "example:run:#{id}:telemetry"
  def pubsub_topic(_, _), do: "example:updates"

  # Helper functions

  @doc """
  Creates a run for testing. Not part of the Backend behaviour.
  """
  def create_run(experiment_id, attrs \\ %{}) do
    id = next_id(:run_id)
    now = DateTime.utc_now()

    run = %{
      id: id,
      experiment_id: experiment_id,
      status: "pending",
      started_at: nil,
      completed_at: nil,
      checkpoint_path: attrs[:checkpoint_path],
      metrics: attrs[:metrics] || %{},
      hyperparameters: attrs[:hyperparameters] || %{},
      inserted_at: now,
      updated_at: now
    }

    :ets.insert(:runs, {id, run})
    broadcast({:run_created, run})
    {:ok, run}
  end

  @doc """
  Records a telemetry event. Not part of the Backend behaviour.
  """
  def record_telemetry(run_id, event_type, data) do
    id = next_id(:telemetry_id)

    event = %{
      id: id,
      run_id: run_id,
      event_type: event_type,
      data: data,
      recorded_at: DateTime.utc_now()
    }

    :ets.insert(:telemetry_events, {id, event})
    broadcast({:telemetry_event, event})
    {:ok, event}
  end

  # GenServer callbacks

  @impl GenServer
  def init(_opts) do
    :ets.new(:experiments, [:set, :public, :named_table])
    :ets.new(:runs, [:set, :public, :named_table])
    :ets.new(:telemetry_events, [:set, :public, :named_table])
    :ets.new(:counters, [:set, :public, :named_table])

    :ets.insert(:counters, {:experiment_id, 0})
    :ets.insert(:counters, {:run_id, 0})
    :ets.insert(:counters, {:telemetry_id, 0})

    # Seed with example data
    seed_data()

    {:ok, %{}}
  end

  @impl GenServer
  def handle_call(:list_all_runs, _from, state) do
    runs = :ets.tab2list(:runs) |> Enum.map(fn {_id, run} -> run end)
    {:reply, {:ok, runs}, state}
  end

  # Private helpers

  defp next_id(counter) do
    :ets.update_counter(:counters, counter, {2, 1})
  end

  defp broadcast(message) do
    # In a real app, broadcast via your PubSub
    # Phoenix.PubSub.broadcast(MyApp.PubSub, topic, message)
    :ok
  end

  defp seed_data do
    # Create sample experiments
    {:ok, exp1} =
      create_experiment(%{
        name: "Baseline Model",
        description: "Initial baseline experiment",
        config: %{model: "llama-3.1-8b", epochs: 3}
      })

    {:ok, exp2} =
      create_experiment(%{
        name: "Fine-tuned Model",
        description: "Fine-tuned on domain data",
        config: %{model: "llama-3.1-8b", epochs: 5, learning_rate: 0.0001}
      })

    # Create sample runs
    {:ok, run1} = create_run(exp1.id, %{metrics: %{accuracy: 0.85, loss: 0.23}})
    {:ok, _run2} = create_run(exp2.id, %{metrics: %{accuracy: 0.92, loss: 0.15}})

    # Start first experiment and run
    start_experiment(exp1.id)
    start_run(run1.id)

    # Add telemetry events
    record_telemetry(run1.id, "metric_update", %{epoch: 1, loss: 0.45, accuracy: 0.78})
    record_telemetry(run1.id, "metric_update", %{epoch: 2, loss: 0.32, accuracy: 0.82})
    record_telemetry(run1.id, "metric_update", %{epoch: 3, loss: 0.23, accuracy: 0.85})
  end
end
