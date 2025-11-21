defmodule CrucibleUIWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint CrucibleUIWeb.Endpoint

      use CrucibleUIWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import CrucibleUIWeb.ConnCase
      import CrucibleUI.Factory
    end
  end

  setup tags do
    CrucibleUI.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
