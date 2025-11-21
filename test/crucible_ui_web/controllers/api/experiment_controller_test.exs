defmodule CrucibleUIWeb.API.ExperimentControllerTest do
  use CrucibleUIWeb.ConnCase, async: true

  # alias CrucibleUI.Experiments.Experiment

  @create_attrs %{
    name: "Test Experiment",
    description: "Test description",
    status: "pending",
    config: %{}
  }
  @update_attrs %{
    name: "Updated Experiment",
    description: "Updated description"
  }
  @invalid_attrs %{name: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all experiments", %{conn: conn} do
      conn = get(conn, ~p"/api/experiments")
      assert json_response(conn, 200)["data"] == []
    end

    test "lists experiments when present", %{conn: conn} do
      insert(:experiment, name: "Exp 1")
      conn = get(conn, ~p"/api/experiments")
      assert [%{"name" => "Exp 1"}] = json_response(conn, 200)["data"]
    end
  end

  describe "create experiment" do
    test "renders experiment when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/experiments", experiment: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/experiments/#{id}")

      assert %{
               "id" => ^id,
               "name" => "Test Experiment",
               "description" => "Test description",
               "status" => "pending"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/experiments", experiment: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show experiment" do
    test "renders experiment", %{conn: conn} do
      experiment = insert(:experiment)
      conn = get(conn, ~p"/api/experiments/#{experiment.id}")
      assert json_response(conn, 200)["data"]["id"] == experiment.id
    end
  end

  describe "update experiment" do
    test "renders experiment when data is valid", %{conn: conn} do
      experiment = insert(:experiment)
      conn = put(conn, ~p"/api/experiments/#{experiment.id}", experiment: @update_attrs)
      assert %{"id" => id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/experiments/#{id}")

      assert %{
               "id" => ^id,
               "name" => "Updated Experiment"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      experiment = insert(:experiment)
      conn = put(conn, ~p"/api/experiments/#{experiment.id}", experiment: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete experiment" do
    test "deletes chosen experiment", %{conn: conn} do
      experiment = insert(:experiment)
      conn = delete(conn, ~p"/api/experiments/#{experiment.id}")
      assert response(conn, 204)
    end
  end
end
