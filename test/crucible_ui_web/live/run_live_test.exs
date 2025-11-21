defmodule CrucibleUIWeb.RunLiveTest do
  use CrucibleUIWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Show" do
    test "displays run", %{conn: conn} do
      run = insert(:run)

      {:ok, _view, html} = live(conn, ~p"/runs/#{run.id}")

      assert html =~ "Run ##{run.id}"
      assert html =~ run.experiment.name
    end

    test "displays run metrics", %{conn: conn} do
      run = insert(:run, metrics: %{"accuracy" => 0.95})

      {:ok, _view, html} = live(conn, ~p"/runs/#{run.id}")

      assert html =~ "Metrics"
      assert html =~ "accuracy"
    end

    test "displays telemetry events", %{conn: conn} do
      run = insert(:run)
      insert(:telemetry_event, run_id: run.id, event_type: "test.event")

      {:ok, _view, html} = live(conn, ~p"/runs/#{run.id}")

      assert html =~ "Telemetry Events"
      assert html =~ "test.event"
    end
  end
end
