defmodule CrucibleUI.Runs.Run do
  @moduledoc """
  Schema for experiment runs in the Crucible UI system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          status: String.t() | nil,
          metrics: map() | nil,
          hyperparameters: map() | nil,
          checkpoint_path: String.t() | nil,
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          experiment_id: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "runs" do
    field :status, :string, default: "pending"
    field :metrics, :map, default: %{}
    field :hyperparameters, :map, default: %{}
    field :checkpoint_path, :string
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    belongs_to :experiment, CrucibleUI.Experiments.Experiment
    has_many :telemetry_events, CrucibleUI.Telemetry.Event
    has_many :statistical_results, CrucibleUI.Statistics.Result

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(run, attrs) do
    run
    |> cast(attrs, [
      :status,
      :metrics,
      :hyperparameters,
      :checkpoint_path,
      :started_at,
      :completed_at,
      :experiment_id
    ])
    |> validate_required([:experiment_id])
    |> validate_inclusion(:status, ["pending", "running", "completed", "failed"])
    |> foreign_key_constraint(:experiment_id)
  end
end
