defmodule CrucibleUIWeb.Router do
  use CrucibleUIWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CrucibleUIWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CrucibleUIWeb do
    pipe_through :browser

    live "/", DashboardLive, :index

    live "/experiments", ExperimentLive.Index, :index
    live "/experiments/new", ExperimentLive.Index, :new
    live "/experiments/:id", ExperimentLive.Show, :show
    live "/experiments/:id/edit", ExperimentLive.Show, :edit

    live "/runs/:id", RunLive.Show, :show

    live "/statistics", StatisticsLive, :index
    live "/statistics/:id", StatisticsLive, :show

    live "/ensemble", EnsembleLive, :index
    live "/hedging", HedgingLive, :index
  end

  scope "/api", CrucibleUIWeb.API do
    pipe_through :api

    resources "/experiments", ExperimentController, except: [:new, :edit]
    resources "/telemetry", TelemetryController, only: [:index, :create, :show]
    resources "/models", ModelController, except: [:new, :edit]
  end

  scope "/api/v1", CrucibleUIWeb.API do
    pipe_through :api

    post "/jobs", TinkexJobController, :create
    get "/jobs/:id", TinkexJobController, :show
    get "/jobs/:id/stream", TinkexJobController, :stream
    post "/jobs/:id/cancel", TinkexJobController, :cancel
  end

  if Application.compile_env(:crucible_ui, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CrucibleUIWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
