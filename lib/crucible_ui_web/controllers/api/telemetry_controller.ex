defmodule CrucibleUIWeb.API.TelemetryController do
  @moduledoc """
  REST API controller for telemetry events.
  """
  use CrucibleUIWeb, :controller

  alias CrucibleUI.Telemetry
  alias CrucibleUI.Telemetry.Event

  action_fallback CrucibleUIWeb.FallbackController

  @doc """
  List telemetry events.
  """
  def index(conn, params) do
    events =
      case params do
        %{"experiment_id" => experiment_id} ->
          Telemetry.list_events_for_experiment(String.to_integer(experiment_id))

        %{"run_id" => run_id} ->
          Telemetry.list_events_for_run(String.to_integer(run_id))

        _ ->
          Telemetry.list_events()
      end

    render(conn, :index, events: events)
  end

  @doc """
  Create a telemetry event.
  """
  def create(conn, %{"event" => event_params}) do
    with {:ok, %Event{} = event} <- Telemetry.create_event(event_params) do
      conn
      |> put_status(:created)
      |> render(:show, event: event)
    end
  end

  @doc """
  Show a single telemetry event.
  """
  def show(conn, %{"id" => id}) do
    event = Telemetry.get_event!(id)
    render(conn, :show, event: event)
  end
end
