defmodule CrucibleUI.ExperimentsTest do
  use CrucibleUI.DataCase, async: true

  alias CrucibleUI.Experiments
  alias CrucibleUI.Experiments.Experiment

  describe "list_experiments/0" do
    test "returns all experiments" do
      experiment = insert(:experiment)
      assert [%Experiment{id: id}] = Experiments.list_experiments()
      assert id == experiment.id
    end

    test "returns empty list when no experiments" do
      assert [] = Experiments.list_experiments()
    end
  end

  describe "list_experiments_by_status/1" do
    test "returns experiments with matching status" do
      insert(:experiment, status: "pending")
      insert(:experiment, status: "running")

      results = Experiments.list_experiments_by_status("pending")
      assert length(results) == 1
      assert hd(results).status == "pending"
    end
  end

  describe "get_experiment!/1" do
    test "returns the experiment with given id" do
      experiment = insert(:experiment)
      assert Experiments.get_experiment!(experiment.id).id == experiment.id
    end

    test "raises when experiment not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Experiments.get_experiment!(999_999)
      end
    end
  end

  describe "create_experiment/1" do
    test "creates experiment with valid data" do
      attrs = %{name: "Test Experiment", description: "Test description", status: "pending"}
      assert {:ok, %Experiment{} = experiment} = Experiments.create_experiment(attrs)
      assert experiment.name == "Test Experiment"
      assert experiment.description == "Test description"
      assert experiment.status == "pending"
    end

    test "returns error with invalid data" do
      assert {:error, %Ecto.Changeset{}} = Experiments.create_experiment(%{name: nil})
    end

    test "returns error with invalid status" do
      attrs = %{name: "Test", status: "invalid_status"}
      assert {:error, changeset} = Experiments.create_experiment(attrs)
      assert "is invalid" in errors_on(changeset).status
    end
  end

  describe "update_experiment/2" do
    test "updates experiment with valid data" do
      experiment = insert(:experiment)
      attrs = %{name: "Updated Name"}
      assert {:ok, %Experiment{} = updated} = Experiments.update_experiment(experiment, attrs)
      assert updated.name == "Updated Name"
    end

    test "returns error with invalid data" do
      experiment = insert(:experiment)
      assert {:error, %Ecto.Changeset{}} = Experiments.update_experiment(experiment, %{name: nil})
    end
  end

  describe "delete_experiment/1" do
    test "deletes the experiment" do
      experiment = insert(:experiment)
      assert {:ok, %Experiment{}} = Experiments.delete_experiment(experiment)
      assert_raise Ecto.NoResultsError, fn -> Experiments.get_experiment!(experiment.id) end
    end
  end

  describe "change_experiment/2" do
    test "returns a changeset" do
      experiment = insert(:experiment)
      assert %Ecto.Changeset{} = Experiments.change_experiment(experiment)
    end
  end

  describe "start_experiment/1" do
    test "sets status to running and started_at" do
      experiment = insert(:experiment, status: "pending")
      assert {:ok, %Experiment{} = started} = Experiments.start_experiment(experiment)
      assert started.status == "running"
      assert started.started_at != nil
    end
  end

  describe "complete_experiment/1" do
    test "sets status to completed and completed_at" do
      experiment = insert(:experiment, status: "running")
      assert {:ok, %Experiment{} = completed} = Experiments.complete_experiment(experiment)
      assert completed.status == "completed"
      assert completed.completed_at != nil
    end
  end

  describe "fail_experiment/1" do
    test "sets status to failed and completed_at" do
      experiment = insert(:experiment, status: "running")
      assert {:ok, %Experiment{} = failed} = Experiments.fail_experiment(experiment)
      assert failed.status == "failed"
      assert failed.completed_at != nil
    end
  end
end
