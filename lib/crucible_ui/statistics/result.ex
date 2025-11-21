defmodule CrucibleUI.Statistics.Result do
  @moduledoc """
  Schema for statistical results in the Crucible UI system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          test_type: String.t() | nil,
          results: map() | nil,
          p_value: float() | nil,
          effect_size: float() | nil,
          effect_size_type: String.t() | nil,
          confidence_interval: [float()] | nil,
          sample_sizes: [integer()] | nil,
          run_id: integer() | nil,
          experiment_id: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "statistical_results" do
    field :test_type, :string
    field :results, :map, default: %{}
    field :p_value, :float
    field :effect_size, :float
    field :effect_size_type, :string
    field :confidence_interval, {:array, :float}, default: []
    field :sample_sizes, {:array, :integer}, default: []

    belongs_to :run, CrucibleUI.Runs.Run
    belongs_to :experiment, CrucibleUI.Experiments.Experiment

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(result, attrs) do
    result
    |> cast(attrs, [
      :test_type,
      :results,
      :p_value,
      :effect_size,
      :effect_size_type,
      :confidence_interval,
      :sample_sizes,
      :run_id,
      :experiment_id
    ])
    |> validate_required([:test_type])
    |> validate_number(:p_value, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> foreign_key_constraint(:run_id)
    |> foreign_key_constraint(:experiment_id)
  end
end
