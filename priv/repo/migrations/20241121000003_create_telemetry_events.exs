defmodule CrucibleUI.Repo.Migrations.CreateTelemetryEvents do
  use Ecto.Migration

  def change do
    create table(:telemetry_events) do
      add :event_type, :string, null: false
      add :data, :map, default: %{}
      add :measurements, :map, default: %{}
      add :metadata, :map, default: %{}
      add :recorded_at, :utc_datetime, null: false
      add :run_id, references(:runs, on_delete: :delete_all)
      add :experiment_id, references(:experiments, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:telemetry_events, [:run_id])
    create index(:telemetry_events, [:experiment_id])
    create index(:telemetry_events, [:event_type])
    create index(:telemetry_events, [:recorded_at])
  end
end
