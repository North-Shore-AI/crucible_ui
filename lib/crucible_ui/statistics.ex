defmodule CrucibleUI.Statistics do
  @moduledoc """
  The Statistics context - manages statistical test results.
  """

  import Ecto.Query, warn: false
  alias CrucibleUI.Repo
  alias CrucibleUI.Statistics.Result

  @doc """
  Returns the list of statistical results.
  """
  @spec list_results() :: [Result.t()]
  def list_results do
    Result
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns results for a specific run.
  """
  @spec list_results_for_run(integer()) :: [Result.t()]
  def list_results_for_run(run_id) do
    Result
    |> where([r], r.run_id == ^run_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns results for a specific experiment.
  """
  @spec list_results_for_experiment(integer()) :: [Result.t()]
  def list_results_for_experiment(experiment_id) do
    Result
    |> where([r], r.experiment_id == ^experiment_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns results filtered by test type.
  """
  @spec list_results_by_type(String.t()) :: [Result.t()]
  def list_results_by_type(test_type) do
    Result
    |> where([r], r.test_type == ^test_type)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns significant results (p < 0.05).
  """
  @spec list_significant_results() :: [Result.t()]
  def list_significant_results do
    Result
    |> where([r], r.p_value < 0.05)
    |> order_by(asc: :p_value)
    |> Repo.all()
  end

  @doc """
  Gets a single result.

  Raises `Ecto.NoResultsError` if the Result does not exist.
  """
  @spec get_result!(integer()) :: Result.t()
  def get_result!(id), do: Repo.get!(Result, id)

  @doc """
  Creates a result.
  """
  @spec create_result(map()) :: {:ok, Result.t()} | {:error, Ecto.Changeset.t()}
  def create_result(attrs \\ %{}) do
    %Result{}
    |> Result.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a result.
  """
  @spec update_result(Result.t(), map()) :: {:ok, Result.t()} | {:error, Ecto.Changeset.t()}
  def update_result(%Result{} = result, attrs) do
    result
    |> Result.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a result.
  """
  @spec delete_result(Result.t()) :: {:ok, Result.t()} | {:error, Ecto.Changeset.t()}
  def delete_result(%Result{} = result) do
    Repo.delete(result)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking result changes.
  """
  @spec change_result(Result.t(), map()) :: Ecto.Changeset.t()
  def change_result(%Result{} = result, attrs \\ %{}) do
    Result.changeset(result, attrs)
  end

  @doc """
  Calculates the significance level.
  """
  @spec significance_level(float()) :: String.t()
  def significance_level(p_value) when p_value < 0.001, do: "***"
  def significance_level(p_value) when p_value < 0.01, do: "**"
  def significance_level(p_value) when p_value < 0.05, do: "*"
  def significance_level(_p_value), do: "ns"

  @doc """
  Interprets effect size based on Cohen's conventions.
  """
  @spec interpret_effect_size(float(), String.t()) :: String.t()
  def interpret_effect_size(effect_size, "cohens_d") do
    abs_effect = abs(effect_size)

    cond do
      abs_effect >= 0.8 -> "large"
      abs_effect >= 0.5 -> "medium"
      abs_effect >= 0.2 -> "small"
      true -> "negligible"
    end
  end

  def interpret_effect_size(effect_size, "eta_squared") do
    cond do
      effect_size >= 0.14 -> "large"
      effect_size >= 0.06 -> "medium"
      effect_size >= 0.01 -> "small"
      true -> "negligible"
    end
  end

  def interpret_effect_size(_effect_size, _type), do: "unknown"
end
