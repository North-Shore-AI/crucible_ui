defmodule CrucibleUIWeb.StatisticsLiveTest do
  use CrucibleUIWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Index" do
    test "renders statistics page with composable placeholder", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/statistics")

      assert html =~ "Statistics"
      assert html =~ "Statistical analysis and visualizations"
      assert html =~ "Statistics visualization module"
      assert html =~ "Host applications can implement custom statistics views"
    end

    test "shows back navigation", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/statistics")

      assert html =~ "Back to experiments"
    end
  end
end
