defmodule CrucibleUI.StatisticsTest do
  use CrucibleUI.DataCase, async: true

  alias CrucibleUI.Statistics
  alias CrucibleUI.Statistics.Result

  describe "list_results/0" do
    test "returns all results" do
      result = insert(:statistical_result)
      assert [%Result{id: id}] = Statistics.list_results()
      assert id == result.id
    end
  end

  describe "list_results_for_run/1" do
    test "returns results for specific run" do
      run = insert(:run)
      result = insert(:statistical_result, run_id: run.id)
      _other_result = insert(:statistical_result)

      results = Statistics.list_results_for_run(run.id)
      assert length(results) == 1
      assert hd(results).id == result.id
    end
  end

  describe "list_results_for_experiment/1" do
    test "returns results for specific experiment" do
      experiment = insert(:experiment)
      result = insert(:statistical_result, experiment_id: experiment.id)
      _other_result = insert(:statistical_result)

      results = Statistics.list_results_for_experiment(experiment.id)
      assert length(results) == 1
      assert hd(results).id == result.id
    end
  end

  describe "list_results_by_type/1" do
    test "returns results with matching type" do
      insert(:statistical_result, test_type: "t_test")
      insert(:statistical_result, test_type: "anova")

      results = Statistics.list_results_by_type("t_test")
      assert length(results) == 1
      assert hd(results).test_type == "t_test"
    end
  end

  describe "list_significant_results/0" do
    test "returns results with p < 0.05" do
      insert(:statistical_result, p_value: 0.01)
      insert(:statistical_result, p_value: 0.10)

      results = Statistics.list_significant_results()
      assert length(results) == 1
      assert hd(results).p_value == 0.01
    end
  end

  describe "get_result!/1" do
    test "returns the result with given id" do
      result = insert(:statistical_result)
      assert Statistics.get_result!(result.id).id == result.id
    end
  end

  describe "create_result/1" do
    test "creates result with valid data" do
      attrs = %{test_type: "t_test", p_value: 0.03, effect_size: 0.5}
      assert {:ok, %Result{} = result} = Statistics.create_result(attrs)
      assert result.test_type == "t_test"
      assert result.p_value == 0.03
    end

    test "returns error with invalid p_value" do
      attrs = %{test_type: "t_test", p_value: 1.5}
      assert {:error, changeset} = Statistics.create_result(attrs)
      assert "must be less than or equal to 1" in errors_on(changeset).p_value
    end
  end

  describe "update_result/2" do
    test "updates result with valid data" do
      result = insert(:statistical_result)
      attrs = %{p_value: 0.001}
      assert {:ok, %Result{} = updated} = Statistics.update_result(result, attrs)
      assert updated.p_value == 0.001
    end
  end

  describe "delete_result/1" do
    test "deletes the result" do
      result = insert(:statistical_result)
      assert {:ok, %Result{}} = Statistics.delete_result(result)
      assert_raise Ecto.NoResultsError, fn -> Statistics.get_result!(result.id) end
    end
  end

  describe "significance_level/1" do
    test "returns *** for p < 0.001" do
      assert Statistics.significance_level(0.0001) == "***"
    end

    test "returns ** for p < 0.01" do
      assert Statistics.significance_level(0.005) == "**"
    end

    test "returns * for p < 0.05" do
      assert Statistics.significance_level(0.03) == "*"
    end

    test "returns ns for p >= 0.05" do
      assert Statistics.significance_level(0.10) == "ns"
    end
  end

  describe "interpret_effect_size/2" do
    test "interprets Cohen's d effect sizes" do
      assert Statistics.interpret_effect_size(0.1, "cohens_d") == "negligible"
      assert Statistics.interpret_effect_size(0.3, "cohens_d") == "small"
      assert Statistics.interpret_effect_size(0.6, "cohens_d") == "medium"
      assert Statistics.interpret_effect_size(1.0, "cohens_d") == "large"
    end

    test "interprets eta-squared effect sizes" do
      assert Statistics.interpret_effect_size(0.005, "eta_squared") == "negligible"
      assert Statistics.interpret_effect_size(0.03, "eta_squared") == "small"
      assert Statistics.interpret_effect_size(0.08, "eta_squared") == "medium"
      assert Statistics.interpret_effect_size(0.20, "eta_squared") == "large"
    end
  end
end
