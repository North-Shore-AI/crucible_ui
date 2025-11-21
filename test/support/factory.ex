defmodule CrucibleUI.Factory do
  @moduledoc """
  Factory for creating test data.
  """
  use ExMachina.Ecto, repo: CrucibleUI.Repo

  alias CrucibleUI.Experiments.Experiment
  alias CrucibleUI.Runs.Run
  alias CrucibleUI.Telemetry.Event
  alias CrucibleUI.Models.Model
  alias CrucibleUI.Statistics.Result

  def experiment_factory do
    %Experiment{
      name: sequence(:name, &"Experiment #{&1}"),
      description: "Test experiment description",
      status: "pending",
      config: %{"learning_rate" => 0.001, "epochs" => 10}
    }
  end

  def run_factory do
    %Run{
      status: "pending",
      metrics: %{"accuracy" => 0.85, "loss" => 0.15},
      hyperparameters: %{"batch_size" => 32},
      experiment: build(:experiment)
    }
  end

  def telemetry_event_factory do
    %Event{
      event_type: sequence(:event_type, &"event.type.#{&1}"),
      data: %{"key" => "value"},
      measurements: %{"duration" => 100},
      metadata: %{"source" => "test"},
      recorded_at: DateTime.utc_now()
    }
  end

  def model_factory do
    %Model{
      name: sequence(:name, &"Model #{&1}"),
      base_model: "gpt-4",
      lora_config: %{"rank" => 8, "alpha" => 16},
      checkpoints: [],
      metadata: %{}
    }
  end

  def statistical_result_factory do
    %Result{
      test_type: "t_test",
      results: %{"statistic" => 2.5},
      p_value: 0.02,
      effect_size: 0.6,
      effect_size_type: "cohens_d",
      confidence_interval: [0.1, 0.9],
      sample_sizes: [30, 30]
    }
  end
end
