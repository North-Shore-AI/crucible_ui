defmodule CrucibleUI.Experiments.Experiment do
  @moduledoc """
  Schema for experiments in the Crucible UI system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          description: String.t() | nil,
          status: String.t() | nil,
          config: map() | nil,
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "experiments" do
    field :name, :string
    field :description, :string
    field :status, :string, default: "pending"
    field :config, :map, default: %{}
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    has_many :runs, CrucibleUI.Runs.Run
    has_many :telemetry_events, CrucibleUI.Telemetry.Event
    has_many :statistical_results, CrucibleUI.Statistics.Result

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(experiment, attrs) do
    experiment
    |> cast(attrs, [:name, :description, :status, :config, :started_at, :completed_at])
    |> validate_required([:name])
    |> validate_inclusion(:status, ["pending", "running", "completed", "failed", "cancelled"])
    |> validate_length(:name, min: 1, max: 255)
  end
end
