defmodule CrucibleUI.Repo.Migrations.CreateStatisticalResults do
  use Ecto.Migration

  def change do
    create table(:statistical_results) do
      add :test_type, :string, null: false
      add :results, :map, default: %{}
      add :p_value, :float
      add :effect_size, :float
      add :effect_size_type, :string
      add :confidence_interval, {:array, :float}, default: []
      add :sample_sizes, {:array, :integer}, default: []
      add :run_id, references(:runs, on_delete: :delete_all)
      add :experiment_id, references(:experiments, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:statistical_results, [:run_id])
    create index(:statistical_results, [:experiment_id])
    create index(:statistical_results, [:test_type])
    create index(:statistical_results, [:p_value])
  end
end
