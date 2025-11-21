defmodule CrucibleUIWeb.API.TelemetryJSON do
  @moduledoc """
  JSON rendering for telemetry events.
  """
  alias CrucibleUI.Telemetry.Event

  @doc """
  Renders a list of events.
  """
  def index(%{events: events}) do
    %{data: for(event <- events, do: data(event))}
  end

  @doc """
  Renders a single event.
  """
  def show(%{event: event}) do
    %{data: data(event)}
  end

  defp data(%Event{} = event) do
    %{
      id: event.id,
      event_type: event.event_type,
      data: event.data,
      measurements: event.measurements,
      metadata: event.metadata,
      recorded_at: event.recorded_at,
      run_id: event.run_id,
      experiment_id: event.experiment_id
    }
  end
end
