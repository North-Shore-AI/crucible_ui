defmodule Crucible.UI.Router do
  @moduledoc """
  Router macro for mounting Crucible UI experiment dashboard in host applications.

  This module provides a composable way to mount the complete Crucible UI feature
  set into any Phoenix application with a single macro call.

  ## Usage

      # In your Phoenix router
      defmodule MyAppWeb.Router do
        use MyAppWeb, :router
        import Crucible.UI.Router

        scope "/experiments" do
          pipe_through [:browser, :require_authenticated]

          experiment_routes "/",
            backend: MyApp.CrucibleBackend,
            on_mount: [MyAppWeb.RequireAuth],
            root_layout: {MyAppWeb.Layouts, :app},
            telemetry_prefix: [:my_app, :experiments]
        end
      end

  ## Options

    * `:backend` (required) - Module implementing `Crucible.UI.Backend` behaviour
    * `:on_mount` - List of LiveView mount hooks for authentication/authorization
    * `:root_layout` - Root layout tuple `{Module, :template}`
    * `:telemetry_prefix` - Telemetry event prefix (default: `[:crucible, :ui]`)
    * `:pubsub` - PubSub module (default: inferred from backend config)

  ## Routes Created

  The macro creates these LiveView routes:

    * `GET {path}` - Dashboard (experiments list, system overview)
    * `GET {path}/experiments` - Experiments index
    * `GET {path}/experiments/new` - New experiment form (modal)
    * `GET {path}/experiments/:id` - Experiment details
    * `GET {path}/experiments/:id/edit` - Edit experiment (modal)
    * `GET {path}/runs/:id` - Run details
    * `GET {path}/statistics` - Statistics overview
    * `GET {path}/statistics/:id` - Specific statistics
    * `GET {path}/ensemble` - Ensemble voting visualization
    * `GET {path}/hedging` - Request hedging visualization

  ## Security

  All routes are isolated in a `live_session` block, which means:

  - Authentication hooks (`on_mount`) run for all routes
  - Navigation within the session doesn't reload authentication
  - Different sessions force full page reload (security boundary)

  ## Example with Multiple Apps

      # CNS UI mounting Crucible experiments
      defmodule CnsUiWeb.Router do
        import Crucible.UI.Router

        scope "/experiments" do
          pipe_through [:browser, :require_researcher]

          experiment_routes "/",
            backend: CnsUi.ExperimentBackend,
            root_layout: {CnsUiWeb.Layouts, :app},
            telemetry_prefix: [:cns_ui, :experiments]
        end
      end

      # Crucible UI (original app)
      defmodule CrucibleUIWeb.Router do
        import Crucible.UI.Router

        scope "/" do
          pipe_through :browser

          experiment_routes "/",
            backend: CrucibleUI.DefaultBackend,
            root_layout: {CrucibleUIWeb.Layouts, :root}
        end
      end
  """

  @doc """
  Mounts Crucible UI experiment routes at the given path.

  ## Parameters

    * `path` - Base path for all routes (e.g., "/", "/experiments")
    * `opts` - Keyword list of options (see module documentation)

  ## Examples

      # Mount at root with all features
      experiment_routes "/", backend: MyBackend

      # Mount under /experiments with auth
      experiment_routes "/experiments",
        backend: MyBackend,
        on_mount: [MyApp.RequireAuth]

      # Mount with custom layout
      experiment_routes "/",
        backend: MyBackend,
        root_layout: {MyAppWeb.Layouts, :dashboard}
  """
  defmacro experiment_routes(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      import Phoenix.LiveView.Router

      # Validate required options
      backend = Keyword.fetch!(opts, :backend)

      # Build session data
      session = %{
        "crucible_backend" => backend,
        "telemetry_prefix" => opts[:telemetry_prefix] || [:crucible, :ui],
        "pubsub" => opts[:pubsub]
      }

      # Create isolated live session for all Crucible UI routes
      live_session :crucible_experiments,
        on_mount: opts[:on_mount] || [],
        root_layout: opts[:root_layout],
        session: session do
        # Dashboard (main entry point)
        live "#{path}", Crucible.UI.DashboardLive, :index

        # Experiment management
        live "#{path}/experiments", Crucible.UI.ExperimentListLive, :index
        live "#{path}/experiments/new", Crucible.UI.ExperimentListLive, :new
        live "#{path}/experiments/:id", Crucible.UI.ExperimentShowLive, :show
        live "#{path}/experiments/:id/edit", Crucible.UI.ExperimentShowLive, :edit

        # Run details
        live "#{path}/runs/:id", Crucible.UI.RunShowLive, :show

        # Statistics
        live "#{path}/statistics", Crucible.UI.StatisticsLive, :index
        live "#{path}/statistics/:id", Crucible.UI.StatisticsLive, :show

        # Advanced features
        live "#{path}/ensemble", Crucible.UI.EnsembleLive, :index
        live "#{path}/hedging", Crucible.UI.HedgingLive, :index
      end
    end
  end
end
