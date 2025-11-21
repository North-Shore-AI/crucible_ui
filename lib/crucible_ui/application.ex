defmodule CrucibleUI.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CrucibleUIWeb.Telemetry,
      CrucibleUI.Repo,
      {DNSCluster, query: Application.get_env(:crucible_ui, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CrucibleUI.PubSub},
      {Finch, name: CrucibleUI.Finch},
      CrucibleUIWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: CrucibleUI.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    CrucibleUIWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
