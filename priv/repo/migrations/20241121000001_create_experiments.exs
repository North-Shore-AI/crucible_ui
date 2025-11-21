defmodule CrucibleUI.Repo.Migrations.CreateExperiments do
  use Ecto.Migration

  def change do
    create table(:experiments) do
      add :name, :string, null: false
      add :description, :text
      add :status, :string, default: "pending", null: false
      add :config, :map, default: %{}
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:experiments, [:status])
    create index(:experiments, [:started_at])
    create index(:experiments, [:name])
  end
end
