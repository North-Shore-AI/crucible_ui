defmodule CrucibleUIWeb.EnsembleLiveTest do
  use CrucibleUIWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Index" do
    test "renders ensemble dashboard", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/ensemble")

      assert html =~ "Ensemble Dashboard"
      assert html =~ "Voting Strategy"
      assert html =~ "Majority"
    end

    test "selects voting strategy", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/ensemble")

      html =
        view
        |> element("button", "Weighted")
        |> render_click()

      assert html =~ "Weighted"
    end
  end
end
