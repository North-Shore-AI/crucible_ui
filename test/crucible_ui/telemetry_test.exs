defmodule CrucibleUI.TelemetryTest do
  use CrucibleUI.DataCase, async: true

  alias CrucibleUI.Telemetry
  alias CrucibleUI.Telemetry.Event

  describe "list_events/0" do
    test "returns all events" do
      event = insert(:telemetry_event)
      assert [%Event{id: id}] = Telemetry.list_events()
      assert id == event.id
    end
  end

  describe "list_events_for_run/1" do
    test "returns events for specific run" do
      run = insert(:run)
      event = insert(:telemetry_event, run_id: run.id)
      _other_event = insert(:telemetry_event)

      results = Telemetry.list_events_for_run(run.id)
      assert length(results) == 1
      assert hd(results).id == event.id
    end
  end

  describe "list_events_for_experiment/1" do
    test "returns events for specific experiment" do
      experiment = insert(:experiment)
      event = insert(:telemetry_event, experiment_id: experiment.id)
      _other_event = insert(:telemetry_event)

      results = Telemetry.list_events_for_experiment(experiment.id)
      assert length(results) == 1
      assert hd(results).id == event.id
    end
  end

  describe "list_events_by_type/1" do
    test "returns events with matching type" do
      insert(:telemetry_event, event_type: "model.inference")
      insert(:telemetry_event, event_type: "training.step")

      results = Telemetry.list_events_by_type("model.inference")
      assert length(results) == 1
      assert hd(results).event_type == "model.inference"
    end
  end

  describe "get_event!/1" do
    test "returns the event with given id" do
      event = insert(:telemetry_event)
      assert Telemetry.get_event!(event.id).id == event.id
    end
  end

  describe "create_event/1" do
    test "creates event with valid data" do
      attrs = %{
        event_type: "test.event",
        data: %{"key" => "value"},
        recorded_at: DateTime.utc_now()
      }

      assert {:ok, %Event{} = event} = Telemetry.create_event(attrs)
      assert event.event_type == "test.event"
      assert event.data == %{"key" => "value"}
    end

    test "sets recorded_at if not provided" do
      attrs = %{event_type: "test.event"}
      assert {:ok, %Event{} = event} = Telemetry.create_event(attrs)
      assert event.recorded_at != nil
    end

    test "returns error without event_type" do
      assert {:error, %Ecto.Changeset{}} = Telemetry.create_event(%{})
    end
  end

  describe "delete_event/1" do
    test "deletes the event" do
      event = insert(:telemetry_event)
      assert {:ok, %Event{}} = Telemetry.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Telemetry.get_event!(event.id) end
    end
  end
end
