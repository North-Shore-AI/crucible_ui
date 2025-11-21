defmodule CrucibleUIWeb.StatisticsLiveTest do
  use CrucibleUIWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Index" do
    test "lists all statistical results", %{conn: conn} do
      insert(:statistical_result, test_type: "t_test", p_value: 0.03)

      {:ok, _view, html} = live(conn, ~p"/statistics")

      assert html =~ "Statistical Results"
      assert html =~ "t_test"
    end

    test "filters by type", %{conn: conn} do
      insert(:statistical_result, test_type: "t_test")
      insert(:statistical_result, test_type: "anova_result")

      {:ok, view, _html} = live(conn, ~p"/statistics")

      html =
        view
        |> element("select[name=type]")
        |> render_change(%{type: "t_test"})

      assert html =~ "t_test"
      # Check that the anova_result doesn't appear in the results (not in dropdown options)
      refute html =~ "anova_result"
    end

    test "toggles significant only", %{conn: conn} do
      insert(:statistical_result, test_type: "sig", p_value: 0.01)
      insert(:statistical_result, test_type: "not_sig", p_value: 0.10)

      {:ok, view, _html} = live(conn, ~p"/statistics")

      html = view |> element("input[type=checkbox]") |> render_click()

      assert html =~ "sig"
      refute html =~ "not_sig"
    end
  end
end
