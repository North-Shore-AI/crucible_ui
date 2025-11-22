defmodule CrucibleUIWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.
  """
  use CrucibleUIWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: CrucibleUIWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: CrucibleUIWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(json: CrucibleUIWeb.ErrorJSON)
    |> render(:"401")
  end

  def call(conn, {:error, :invalid_request}) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: CrucibleUIWeb.ErrorJSON)
    |> render(:"400")
  end
end
