defmodule CrucibleUI.Models.Model do
  @moduledoc """
  Schema for models in the Crucible UI system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          base_model: String.t() | nil,
          lora_config: map() | nil,
          checkpoints: [String.t()] | nil,
          metadata: map() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "models" do
    field :name, :string
    field :base_model, :string
    field :lora_config, :map, default: %{}
    field :checkpoints, {:array, :string}, default: []
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(model, attrs) do
    model
    |> cast(attrs, [:name, :base_model, :lora_config, :checkpoints, :metadata])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> validate_length(:name, min: 1, max: 255)
  end
end
