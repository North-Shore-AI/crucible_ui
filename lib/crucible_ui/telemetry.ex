defmodule CrucibleUI.Telemetry do
  @moduledoc """
  The Telemetry context - manages telemetry event ingestion and querying.
  """

  import Ecto.Query, warn: false
  alias CrucibleUI.Repo
  alias CrucibleUI.Telemetry.Event
  alias Phoenix.PubSub

  @doc """
  Returns the list of telemetry events.
  """
  @spec list_events() :: [Event.t()]
  def list_events do
    Event
    |> order_by(desc: :recorded_at)
    |> limit(1000)
    |> Repo.all()
  end

  @doc """
  Returns events for a specific run.
  """
  @spec list_events_for_run(integer()) :: [Event.t()]
  def list_events_for_run(run_id) do
    Event
    |> where([e], e.run_id == ^run_id)
    |> order_by(desc: :recorded_at)
    |> Repo.all()
  end

  @doc """
  Returns events for a specific experiment.
  """
  @spec list_events_for_experiment(integer()) :: [Event.t()]
  def list_events_for_experiment(experiment_id) do
    Event
    |> where([e], e.experiment_id == ^experiment_id)
    |> order_by(desc: :recorded_at)
    |> Repo.all()
  end

  @doc """
  Returns events filtered by type.
  """
  @spec list_events_by_type(String.t()) :: [Event.t()]
  def list_events_by_type(event_type) do
    Event
    |> where([e], e.event_type == ^event_type)
    |> order_by(desc: :recorded_at)
    |> Repo.all()
  end

  @doc """
  Returns events within a time range.
  """
  @spec list_events_in_range(DateTime.t(), DateTime.t()) :: [Event.t()]
  def list_events_in_range(start_time, end_time) do
    Event
    |> where([e], e.recorded_at >= ^start_time and e.recorded_at <= ^end_time)
    |> order_by(desc: :recorded_at)
    |> Repo.all()
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.
  """
  @spec get_event!(integer()) :: Event.t()
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates an event.
  """
  @spec create_event(map()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def create_event(attrs \\ %{}) do
    attrs = Map.put_new(attrs, :recorded_at, DateTime.utc_now())

    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:telemetry_event)
  end

  @doc """
  Deletes an event.
  """
  @spec delete_event(Event.t()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.
  """
  @spec change_event(Event.t(), map()) :: Ecto.Changeset.t()
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  @doc """
  Aggregates metrics for events.
  """
  @spec aggregate_metrics(integer(), atom()) :: map()
  def aggregate_metrics(experiment_id, metric_key) do
    Event
    |> where([e], e.experiment_id == ^experiment_id)
    |> select([e], e.measurements)
    |> Repo.all()
    |> Enum.map(&Map.get(&1, to_string(metric_key), 0))
    |> aggregate_stats()
  end

  defp aggregate_stats([]), do: %{count: 0, sum: 0, avg: 0, min: 0, max: 0}

  defp aggregate_stats(values) do
    %{
      count: length(values),
      sum: Enum.sum(values),
      avg: Enum.sum(values) / length(values),
      min: Enum.min(values),
      max: Enum.max(values)
    }
  end

  # PubSub broadcasting
  defp broadcast({:ok, event}, :telemetry_event) do
    PubSub.broadcast(CrucibleUI.PubSub, "telemetry:all", {:telemetry_event, event})

    if event.experiment_id do
      PubSub.broadcast(
        CrucibleUI.PubSub,
        "telemetry:#{event.experiment_id}",
        {:telemetry_event, event}
      )
    end

    if event.run_id do
      PubSub.broadcast(
        CrucibleUI.PubSub,
        "run:#{event.run_id}:telemetry",
        {:telemetry_event, event}
      )
    end

    {:ok, event}
  end

  defp broadcast({:error, _} = error, _event), do: error
end
