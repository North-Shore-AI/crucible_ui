defmodule CrucibleUIWeb.API.TinkexJobController do
  @moduledoc """
  Thin Phoenix wrapper over `Crucible.Tinkex.API.Router` to expose the public
  REST/WebSocket (SSE) surface.
  """

  use CrucibleUIWeb, :controller

  alias Crucible.Tinkex.API.Router, as: TinkexRouter
  alias Crucible.Tinkex.API.Stream, as: TinkexStream

  action_fallback CrucibleUIWeb.FallbackController

  def create(conn, params) do
    case TinkexRouter.submit(%{params: params, headers: conn.req_headers}) do
      {:ok, resp} ->
        conn |> put_status(:accepted) |> json(resp)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def show(conn, %{"id" => job_id}) do
    case TinkexRouter.fetch(%{params: %{}, headers: conn.req_headers}, job_id) do
      {:ok, resp} -> json(conn, resp)
      {:error, reason} -> {:error, reason}
    end
  end

  def cancel(conn, %{"id" => job_id}) do
    case TinkexRouter.cancel(%{params: %{}, headers: conn.req_headers}, job_id) do
      :ok -> conn |> put_status(:accepted) |> json(%{job_id: job_id, status: "canceled"})
      {:error, reason} -> {:error, reason}
    end
  end

  def stream(conn, %{"id" => job_id} = params) do
    with {:ok, stream} <- TinkexRouter.stream(%{params: %{}, headers: conn.req_headers}, job_id) do
      timeout_ms = parse_timeout(params["timeout_ms"] || "5000")

      conn =
        conn
        |> put_resp_content_type("text/event-stream")
        |> put_resp_header("cache-control", "no-cache")
        |> send_chunked(:ok)

      enum = TinkexStream.to_enum(stream.subscribe, timeout: timeout_ms)

      Enum.reduce_while(enum, conn, fn {jid, event}, conn_acc ->
        chunk_data = encode_sse(jid, event)

        case chunk(conn_acc, chunk_data) do
          {:ok, conn_next} -> {:cont, conn_next}
          {:error, :closed} -> {:halt, conn_acc}
        end
      end)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_timeout(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} when int > 0 -> int
      _ -> 5_000
    end
  end

  defp parse_timeout(int) when is_integer(int) and int > 0, do: int
  defp parse_timeout(_), do: 5_000

  defp encode_sse(job_id, %{event: event_name, measurements: meas, metadata: meta}) do
    payload = %{
      job_id: job_id,
      event: event_name,
      measurements: meas,
      metadata: meta
    }

    "event: #{event_name}\ndata: #{Jason.encode!(payload)}\n\n"
  end
end
