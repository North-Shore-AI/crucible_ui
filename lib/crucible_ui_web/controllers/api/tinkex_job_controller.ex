defmodule CrucibleUIWeb.API.TinkexJobController do
  @moduledoc """
  Thin Phoenix wrapper over `Crucible.Tinkex.API.Router` to expose the public
  REST/WebSocket (SSE) surface.

  Requires the optional `crucible_tinkex` dependency.
  """

  use CrucibleUIWeb, :controller

  @tinkex_router Crucible.Tinkex.API.Router
  @tinkex_stream Crucible.Tinkex.API.Stream

  action_fallback CrucibleUIWeb.FallbackController

  @doc """
  Check if Tinkex API is available (optional dependency).
  """
  def tinkex_available? do
    Code.ensure_loaded?(@tinkex_router)
  end

  def create(conn, params) do
    unless tinkex_available?() do
      {:error, :tinkex_not_available}
    else
      case apply(@tinkex_router, :submit, [%{params: params, headers: conn.req_headers}]) do
        {:ok, resp} ->
          conn |> put_status(:accepted) |> json(resp)

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def show(conn, %{"id" => job_id}) do
    unless tinkex_available?() do
      {:error, :tinkex_not_available}
    else
      case apply(@tinkex_router, :fetch, [%{params: %{}, headers: conn.req_headers}, job_id]) do
        {:ok, resp} -> json(conn, resp)
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def cancel(conn, %{"id" => job_id}) do
    unless tinkex_available?() do
      {:error, :tinkex_not_available}
    else
      case apply(@tinkex_router, :cancel, [%{params: %{}, headers: conn.req_headers}, job_id]) do
        :ok -> conn |> put_status(:accepted) |> json(%{job_id: job_id, status: "canceled"})
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def stream(conn, %{"id" => job_id} = params) do
    unless tinkex_available?() do
      {:error, :tinkex_not_available}
    else
      with {:ok, stream} <-
             apply(@tinkex_router, :stream, [%{params: %{}, headers: conn.req_headers}, job_id]) do
        timeout_ms = parse_timeout(params["timeout_ms"] || "5000")

        conn =
          conn
          |> put_resp_content_type("text/event-stream")
          |> put_resp_header("cache-control", "no-cache")
          |> send_chunked(:ok)

        enum = apply(@tinkex_stream, :to_enum, [stream.subscribe, [timeout: timeout_ms]])

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
