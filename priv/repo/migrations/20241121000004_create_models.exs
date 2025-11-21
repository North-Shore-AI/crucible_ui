defmodule CrucibleUI.Repo.Migrations.CreateModels do
  use Ecto.Migration

  def change do
    create table(:models) do
      add :name, :string, null: false
      add :base_model, :string
      add :lora_config, :map, default: %{}
      add :checkpoints, {:array, :string}, default: []
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:models, [:name])
    create index(:models, [:base_model])
  end
end
