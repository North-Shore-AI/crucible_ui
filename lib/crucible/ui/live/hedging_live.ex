defmodule Crucible.UI.HedgingLive do
  @moduledoc """
  LiveView for request hedging visualization (placeholder for composable pattern).

  This LiveView is host-agnostic and uses the backend behaviour for data operations.
  """
  use Phoenix.LiveView

  import Crucible.UI.Components

  @impl true
  def mount(_params, session, socket) do
    backend = session["crucible_backend"]

    {:ok,
     socket
     |> assign(:backend, backend)
     |> assign(:page_title, "Request Hedging")}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Request Hedging
        <:subtitle>Adaptive hedging strategies</:subtitle>
      </.header>

      <div class="mt-8 bg-white shadow rounded-lg p-6">
        <p class="text-sm text-gray-600">
          Request hedging visualization module. This is a placeholder in the composable version.
          Host applications can implement custom hedging views using the backend behaviour.
        </p>
      </div>

      <.back navigate="/experiments">Back to experiments</.back>
    </div>
    """
  end
end
