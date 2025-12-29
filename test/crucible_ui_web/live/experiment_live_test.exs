defmodule CrucibleUIWeb.ExperimentLiveTest do
  use CrucibleUIWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Index" do
    test "lists all experiments", %{conn: conn} do
      _experiment = insert(:experiment, name: "Test Experiment")

      {:ok, _view, html} = live(conn, ~p"/experiments")

      assert html =~ "Experiments"
      assert html =~ "Test Experiment"
    end

    test "shows new experiment link", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/experiments")

      assert view |> element("a", "New Experiment") |> render_click() =~
               "New Experiment"

      assert_patch(view, ~p"/experiments/new")
    end

    test "deletes experiment in listing", %{conn: conn} do
      experiment = insert(:experiment)

      {:ok, view, _html} = live(conn, ~p"/experiments")

      assert view |> element("#experiments-#{experiment.id} a", "Delete") |> render_click()
      refute has_element?(view, "#experiments-#{experiment.id}")
    end
  end

  describe "Show" do
    test "displays experiment", %{conn: conn} do
      experiment = insert(:experiment, name: "Show Test", description: "Description")

      {:ok, _view, html} = live(conn, ~p"/experiments/#{experiment.id}")

      assert html =~ "Show Test"
      assert html =~ "Description"
    end

    test "shows edit link", %{conn: conn} do
      experiment = insert(:experiment)

      {:ok, view, _html} = live(conn, ~p"/experiments/#{experiment.id}")

      # Click the edit button - this should patch the URL
      view |> element("a", "Edit") |> render_click()

      # Verify the URL was patched to the edit route
      assert_patch(view, ~p"/experiments/#{experiment.id}/edit")
    end
  end
end
