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

    test "saves new experiment", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/experiments")

      assert view |> element("a", "New Experiment") |> render_click() =~
               "New Experiment"

      assert_patch(view, ~p"/experiments/new")

      assert view
             |> form("#experiment-form", experiment: %{name: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert view
             |> form("#experiment-form",
               experiment: %{name: "New Test", description: "Description"}
             )
             |> render_submit()

      assert_patch(view, ~p"/experiments")

      html = render(view)
      assert html =~ "Experiment created successfully"
      assert html =~ "New Test"
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

    test "updates experiment within modal", %{conn: conn} do
      experiment = insert(:experiment)

      {:ok, view, _html} = live(conn, ~p"/experiments/#{experiment.id}")

      assert view |> element("a", "Edit") |> render_click() =~
               "Edit #{experiment.name}"

      assert_patch(view, ~p"/experiments/#{experiment.id}/edit")

      assert view
             |> form("#experiment-form", experiment: %{name: "Updated Name"})
             |> render_submit()

      assert_patch(view, ~p"/experiments/#{experiment.id}")

      html = render(view)
      assert html =~ "Experiment updated successfully"
      assert html =~ "Updated Name"
    end
  end
end
