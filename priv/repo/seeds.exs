# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CrucibleUI.Repo.insert!(%CrucibleUI.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias CrucibleUI.Repo
alias CrucibleUI.Experiments.Experiment
alias CrucibleUI.Runs.Run
alias CrucibleUI.Models.Model
alias CrucibleUI.Statistics.Result

# Create sample experiments
experiment1 =
  Repo.insert!(%Experiment{
    name: "LLM Ensemble Accuracy Study",
    description: "Comparing ensemble voting strategies for improved accuracy",
    status: "completed",
    config: %{
      "models" => ["gpt-4", "claude-3", "gemini"],
      "voting_strategy" => "weighted",
      "dataset" => "mmlu"
    },
    started_at: DateTime.add(DateTime.utc_now(), -3600 * 24, :second),
    completed_at: DateTime.add(DateTime.utc_now(), -3600, :second)
  })

experiment2 =
  Repo.insert!(%Experiment{
    name: "Request Hedging Latency Test",
    description: "Measuring P99 latency reduction with hedging strategies",
    status: "running",
    config: %{
      "strategy" => "percentile",
      "percentile_threshold" => 95,
      "max_hedged_requests" => 3
    },
    started_at: DateTime.utc_now()
  })

experiment3 =
  Repo.insert!(%Experiment{
    name: "Data Quality Validation",
    description: "Testing data validation pipelines with ExDataCheck",
    status: "pending",
    config: %{
      "expectations" => ["not_null", "unique", "in_range"],
      "profiling" => true
    }
  })

# Create runs for experiments
run1 =
  Repo.insert!(%Run{
    experiment_id: experiment1.id,
    status: "completed",
    metrics: %{
      "accuracy" => 0.96,
      "f1_score" => 0.94,
      "latency_p50" => 120,
      "latency_p99" => 450
    },
    hyperparameters: %{
      "temperature" => 0.7,
      "max_tokens" => 256
    },
    started_at: DateTime.add(DateTime.utc_now(), -3600 * 24, :second),
    completed_at: DateTime.add(DateTime.utc_now(), -3600 * 23, :second)
  })

run2 =
  Repo.insert!(%Run{
    experiment_id: experiment2.id,
    status: "running",
    metrics: %{
      "requests_processed" => 5420,
      "hedged_requests" => 812,
      "avg_latency" => 85
    },
    hyperparameters: %{
      "hedge_delay_ms" => 50,
      "timeout_ms" => 500
    },
    started_at: DateTime.utc_now()
  })

# Create models
Repo.insert!(%Model{
  name: "GPT-4 Turbo",
  base_model: "gpt-4-turbo-preview",
  lora_config: %{},
  checkpoints: [],
  metadata: %{
    "provider" => "openai",
    "context_window" => 128_000
  }
})

Repo.insert!(%Model{
  name: "Claude 3 Opus",
  base_model: "claude-3-opus-20240229",
  lora_config: %{},
  checkpoints: [],
  metadata: %{
    "provider" => "anthropic",
    "context_window" => 200_000
  }
})

# Create statistical results
Repo.insert!(%Result{
  experiment_id: experiment1.id,
  run_id: run1.id,
  test_type: "t_test",
  results: %{
    "t_statistic" => 3.42,
    "degrees_of_freedom" => 58
  },
  p_value: 0.001,
  effect_size: 0.89,
  effect_size_type: "cohens_d",
  confidence_interval: [0.45, 1.33],
  sample_sizes: [30, 30]
})

Repo.insert!(%Result{
  experiment_id: experiment1.id,
  run_id: run1.id,
  test_type: "mann_whitney",
  results: %{
    "u_statistic" => 156.0
  },
  p_value: 0.023,
  effect_size: 0.65,
  effect_size_type: "cohens_d",
  confidence_interval: [0.21, 1.09],
  sample_sizes: [30, 30]
})

IO.puts("Seeds completed successfully!")
IO.puts("Created #{3} experiments, #{2} runs, #{2} models, and #{2} statistical results.")
