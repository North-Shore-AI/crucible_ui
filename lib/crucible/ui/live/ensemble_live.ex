defmodule Crucible.UI.EnsembleLive do
  @moduledoc """
  LiveView for ensemble voting visualization (placeholder for composable pattern).

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
     |> assign(:page_title, "Ensemble Voting")}
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
        Ensemble Voting
        <:subtitle>Multi-model voting strategies</:subtitle>
      </.header>

      <div class="mt-8 bg-white shadow rounded-lg p-6">
        <p class="text-sm text-gray-600">
          Ensemble voting visualization module. This is a placeholder in the composable version.
          Host applications can implement custom ensemble views using the backend behaviour.
        </p>
      </div>

      <.back navigate="/experiments">Back to experiments</.back>
    </div>
    """
  end
end
