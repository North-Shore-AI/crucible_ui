defmodule CrucibleUI.Telemetry.Event do
  @moduledoc """
  Schema for telemetry events in the Crucible UI system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          event_type: String.t() | nil,
          data: map() | nil,
          measurements: map() | nil,
          metadata: map() | nil,
          recorded_at: DateTime.t() | nil,
          run_id: integer() | nil,
          experiment_id: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "telemetry_events" do
    field :event_type, :string
    field :data, :map, default: %{}
    field :measurements, :map, default: %{}
    field :metadata, :map, default: %{}
    field :recorded_at, :utc_datetime

    belongs_to :run, CrucibleUI.Runs.Run
    belongs_to :experiment, CrucibleUI.Experiments.Experiment

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :event_type,
      :data,
      :measurements,
      :metadata,
      :recorded_at,
      :run_id,
      :experiment_id
    ])
    |> validate_required([:event_type, :recorded_at])
    |> foreign_key_constraint(:run_id)
    |> foreign_key_constraint(:experiment_id)
  end
end
