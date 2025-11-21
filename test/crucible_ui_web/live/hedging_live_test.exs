defmodule CrucibleUIWeb.HedgingLiveTest do
  use CrucibleUIWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Index" do
    test "renders hedging metrics", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/hedging")

      assert html =~ "Hedging Metrics"
      assert html =~ "P50 Latency"
      assert html =~ "P99 Latency"
    end

    test "selects hedging strategy", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/hedging")

      html =
        view
        |> element("button", "Adaptive")
        |> render_click()

      assert html =~ "Adaptive"
    end
  end
end
