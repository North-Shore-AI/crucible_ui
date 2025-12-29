defmodule CrucibleUIWeb.EnsembleLiveTest do
  use CrucibleUIWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Index" do
    test "renders ensemble page with composable placeholder", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/ensemble")

      assert html =~ "Ensemble Voting"
      assert html =~ "Multi-model voting strategies"
      assert html =~ "Ensemble voting visualization module"
      assert html =~ "Host applications can implement custom ensemble views"
    end

    test "shows back navigation", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/ensemble")

      assert html =~ "Back to experiments"
    end
  end
end
