defmodule CrucibleUIWeb.API.ModelController do
  @moduledoc """
  REST API controller for models.
  """
  use CrucibleUIWeb, :controller

  alias CrucibleUI.Models
  alias CrucibleUI.Models.Model

  action_fallback CrucibleUIWeb.FallbackController

  @doc """
  List all models.
  """
  def index(conn, _params) do
    models = Models.list_models()
    render(conn, :index, models: models)
  end

  @doc """
  Create a new model.
  """
  def create(conn, %{"model" => model_params}) do
    with {:ok, %Model{} = model} <- Models.create_model(model_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/models/#{model}")
      |> render(:show, model: model)
    end
  end

  @doc """
  Show a single model.
  """
  def show(conn, %{"id" => id}) do
    model = Models.get_model!(id)
    render(conn, :show, model: model)
  end

  @doc """
  Update a model.
  """
  def update(conn, %{"id" => id, "model" => model_params}) do
    model = Models.get_model!(id)

    with {:ok, %Model{} = model} <- Models.update_model(model, model_params) do
      render(conn, :show, model: model)
    end
  end

  @doc """
  Delete a model.
  """
  def delete(conn, %{"id" => id}) do
    model = Models.get_model!(id)

    with {:ok, %Model{}} <- Models.delete_model(model) do
      send_resp(conn, :no_content, "")
    end
  end
end
