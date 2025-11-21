defmodule CrucibleUIWeb.DashboardLiveTest do
  use CrucibleUIWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Dashboard" do
    test "renders dashboard with stats", %{conn: conn} do
      insert(:experiment)
      insert(:run)

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Dashboard"
      assert html =~ "Total Experiments"
      assert html =~ "Total Runs"
    end

    test "displays recent experiments", %{conn: conn} do
      _experiment = insert(:experiment, name: "Recent Experiment")

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Recent Experiments"
      assert html =~ "Recent Experiment"
    end

    test "displays recent runs", %{conn: conn} do
      run = insert(:run)

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Recent Runs"
      assert html =~ "Run ##{run.id}"
    end
  end
end
