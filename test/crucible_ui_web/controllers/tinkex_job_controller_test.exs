defmodule CrucibleUIWeb.TinkexJobControllerTest do
  use CrucibleUIWeb.ConnCase, async: true

  alias Crucible.Tinkex.TelemetryBroker

  setup do
    Application.put_env(:crucible_framework, :api_tokens, ["test-token"])
    Application.put_env(:crucible_framework, :runner_mode, :simulate)

    :ok
  end

  test "creates and fetches a job", %{conn: conn} do
    conn = put_req_header(conn, "authorization", "Bearer test-token")

    create_conn = post(conn, ~p"/api/v1/jobs", %{"dataset_manifest" => "s3://bucket/ds"})
    assert create_conn.status == 202

    %{"job_id" => job_id} = json_response(create_conn, 202)

    show_conn = get(conn, ~p"/api/v1/jobs/#{job_id}")
    assert show_conn.status == 200
    assert %{"job_id" => ^job_id, "status" => _} = json_response(show_conn, 200)
  end

  test "rejects unauthorized job submission", %{conn: conn} do
    resp = post(conn, ~p"/api/v1/jobs", %{"dataset_manifest" => "s3://bucket/ds"})
    assert resp.status == 401
  end

  test "streams telemetry via SSE", %{conn: conn} do
    conn = put_req_header(conn, "authorization", "Bearer test-token")

    create_conn = post(conn, ~p"/api/v1/jobs", %{"dataset_manifest" => "s3://bucket/ds"})
    %{"job_id" => job_id, "stream_token" => stream_token} = json_response(create_conn, 202)

    # Simulate an event arriving on the broker
    TelemetryBroker.subscribe(job_id)

    spawn(fn ->
      :timer.sleep(50)

      TelemetryBroker.broadcast(job_id, %{
        event: :training_step,
        measurements: %{loss: 0.9},
        metadata: %{step: 1}
      })
    end)

    stream_conn =
      conn
      |> put_req_header("x-stream-token", stream_token)
      |> get(~p"/api/v1/jobs/#{job_id}/stream", %{"timeout_ms" => "200"})

    assert stream_conn.status == 200
    assert stream_conn.resp_body =~ "training_step"
  end
end
