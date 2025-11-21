defmodule CrucibleUI.Repo.Migrations.CreateRuns do
  use Ecto.Migration

  def change do
    create table(:runs) do
      add :status, :string, default: "pending", null: false
      add :metrics, :map, default: %{}
      add :hyperparameters, :map, default: %{}
      add :checkpoint_path, :string
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :experiment_id, references(:experiments, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:runs, [:experiment_id])
    create index(:runs, [:status])
    create index(:runs, [:started_at])
  end
end
