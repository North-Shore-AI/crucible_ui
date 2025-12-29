defmodule CrucibleUIWeb.HedgingLiveTest do
  use CrucibleUIWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Index" do
    test "renders hedging page with composable placeholder", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/hedging")

      assert html =~ "Request Hedging"
      assert html =~ "Adaptive hedging strategies"
      assert html =~ "Request hedging visualization module"
      assert html =~ "Host applications can implement custom hedging views"
    end

    test "shows back navigation", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/hedging")

      assert html =~ "Back to experiments"
    end
  end
end
