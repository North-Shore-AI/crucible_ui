defmodule CrucibleUIWeb.API.ModelJSON do
  @moduledoc """
  JSON rendering for models.
  """
  alias CrucibleUI.Models.Model

  @doc """
  Renders a list of models.
  """
  def index(%{models: models}) do
    %{data: for(model <- models, do: data(model))}
  end

  @doc """
  Renders a single model.
  """
  def show(%{model: model}) do
    %{data: data(model)}
  end

  defp data(%Model{} = model) do
    %{
      id: model.id,
      name: model.name,
      base_model: model.base_model,
      lora_config: model.lora_config,
      checkpoints: model.checkpoints,
      metadata: model.metadata,
      inserted_at: model.inserted_at,
      updated_at: model.updated_at
    }
  end
end
