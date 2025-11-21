defmodule CrucibleUI.Models do
  @moduledoc """
  The Models context - manages model configurations and checkpoints.
  """

  import Ecto.Query, warn: false
  alias CrucibleUI.Repo
  alias CrucibleUI.Models.Model

  @doc """
  Returns the list of models.
  """
  @spec list_models() :: [Model.t()]
  def list_models do
    Model
    |> order_by(asc: :name)
    |> Repo.all()
  end

  @doc """
  Returns models filtered by base model.
  """
  @spec list_models_by_base(String.t()) :: [Model.t()]
  def list_models_by_base(base_model) do
    Model
    |> where([m], m.base_model == ^base_model)
    |> order_by(asc: :name)
    |> Repo.all()
  end

  @doc """
  Gets a single model.

  Raises `Ecto.NoResultsError` if the Model does not exist.
  """
  @spec get_model!(integer()) :: Model.t()
  def get_model!(id), do: Repo.get!(Model, id)

  @doc """
  Gets a model by name.
  """
  @spec get_model_by_name(String.t()) :: Model.t() | nil
  def get_model_by_name(name) do
    Repo.get_by(Model, name: name)
  end

  @doc """
  Creates a model.
  """
  @spec create_model(map()) :: {:ok, Model.t()} | {:error, Ecto.Changeset.t()}
  def create_model(attrs \\ %{}) do
    %Model{}
    |> Model.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a model.
  """
  @spec update_model(Model.t(), map()) :: {:ok, Model.t()} | {:error, Ecto.Changeset.t()}
  def update_model(%Model{} = model, attrs) do
    model
    |> Model.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a model.
  """
  @spec delete_model(Model.t()) :: {:ok, Model.t()} | {:error, Ecto.Changeset.t()}
  def delete_model(%Model{} = model) do
    Repo.delete(model)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking model changes.
  """
  @spec change_model(Model.t(), map()) :: Ecto.Changeset.t()
  def change_model(%Model{} = model, attrs \\ %{}) do
    Model.changeset(model, attrs)
  end

  @doc """
  Adds a checkpoint to a model.
  """
  @spec add_checkpoint(Model.t(), String.t()) :: {:ok, Model.t()} | {:error, Ecto.Changeset.t()}
  def add_checkpoint(%Model{} = model, checkpoint_path) do
    checkpoints = (model.checkpoints || []) ++ [checkpoint_path]
    update_model(model, %{checkpoints: checkpoints})
  end
end
