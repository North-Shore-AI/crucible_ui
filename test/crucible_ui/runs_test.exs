defmodule CrucibleUI.RunsTest do
  use CrucibleUI.DataCase, async: true

  alias CrucibleUI.Runs
  alias CrucibleUI.Runs.Run

  describe "list_runs/0" do
    test "returns all runs" do
      run = insert(:run)
      assert [%Run{id: id}] = Runs.list_runs()
      assert id == run.id
    end

    test "returns empty list when no runs" do
      assert [] = Runs.list_runs()
    end
  end

  describe "list_runs_for_experiment/1" do
    test "returns runs for specific experiment" do
      experiment = insert(:experiment)
      run = insert(:run, experiment: experiment)
      _other_run = insert(:run)

      results = Runs.list_runs_for_experiment(experiment.id)
      assert length(results) == 1
      assert hd(results).id == run.id
    end
  end

  describe "list_runs_by_status/1" do
    test "returns runs with matching status" do
      insert(:run, status: "pending")
      insert(:run, status: "running")

      results = Runs.list_runs_by_status("pending")
      assert length(results) == 1
      assert hd(results).status == "pending"
    end
  end

  describe "get_run!/1" do
    test "returns the run with given id" do
      run = insert(:run)
      assert Runs.get_run!(run.id).id == run.id
    end

    test "raises when run not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Runs.get_run!(999_999)
      end
    end
  end

  describe "create_run/1" do
    test "creates run with valid data" do
      experiment = insert(:experiment)
      attrs = %{experiment_id: experiment.id, status: "pending"}
      assert {:ok, %Run{} = run} = Runs.create_run(attrs)
      assert run.experiment_id == experiment.id
      assert run.status == "pending"
    end

    test "returns error without experiment_id" do
      assert {:error, %Ecto.Changeset{}} = Runs.create_run(%{status: "pending"})
    end
  end

  describe "update_run/2" do
    test "updates run with valid data" do
      run = insert(:run)
      attrs = %{status: "running"}
      assert {:ok, %Run{} = updated} = Runs.update_run(run, attrs)
      assert updated.status == "running"
    end
  end

  describe "delete_run/1" do
    test "deletes the run" do
      run = insert(:run)
      assert {:ok, %Run{}} = Runs.delete_run(run)
      assert_raise Ecto.NoResultsError, fn -> Runs.get_run!(run.id) end
    end
  end

  describe "start_run/1" do
    test "sets status to running and started_at" do
      run = insert(:run, status: "pending")
      assert {:ok, %Run{} = started} = Runs.start_run(run)
      assert started.status == "running"
      assert started.started_at != nil
    end
  end

  describe "complete_run/2" do
    test "sets status to completed with metrics" do
      run = insert(:run, status: "running", metrics: %{"initial" => 1})
      metrics = %{"final_accuracy" => 0.95}
      assert {:ok, %Run{} = completed} = Runs.complete_run(run, metrics)
      assert completed.status == "completed"
      assert completed.completed_at != nil
      assert completed.metrics["final_accuracy"] == 0.95
    end
  end

  describe "fail_run/1" do
    test "sets status to failed and completed_at" do
      run = insert(:run, status: "running")
      assert {:ok, %Run{} = failed} = Runs.fail_run(run)
      assert failed.status == "failed"
      assert failed.completed_at != nil
    end
  end
end
