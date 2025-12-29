defmodule Example.Router do
  @moduledoc """
  Example router configurations for mounting Crucible UI.

  This file demonstrates various ways to integrate Crucible UI routes
  into a Phoenix application.
  """

  # Example 1: Basic mounting (minimal configuration)
  defmodule BasicRouter do
    use Phoenix.Router
    import Crucible.UI.Router

    scope "/" do
      pipe_through :browser

      experiment_routes("/",
        backend: Example.CrucibleBackend
      )
    end
  end

  # Example 2: With authentication
  defmodule AuthenticatedRouter do
    use Phoenix.Router
    import Crucible.UI.Router

    # Authentication hook
    defmodule RequireAuth do
      import Phoenix.LiveView

      def on_mount(:default, _params, %{"user_id" => user_id} = _session, socket) do
        {:cont, assign(socket, :current_user_id, user_id)}
      end

      def on_mount(:default, _params, _session, socket) do
        {:halt, redirect(socket, to: "/login")}
      end
    end

    scope "/experiments" do
      pipe_through [:browser, :require_authenticated]

      experiment_routes("/",
        backend: Example.CrucibleBackend,
        on_mount: [RequireAuth]
      )
    end
  end

  # Example 3: With custom layout and telemetry
  defmodule CustomLayoutRouter do
    use Phoenix.Router
    import Crucible.UI.Router

    scope "/" do
      pipe_through :browser

      experiment_routes("/",
        backend: Example.CrucibleBackend,
        root_layout: {MyAppWeb.Layouts, :dashboard},
        telemetry_prefix: [:my_app, :crucible, :experiments]
      )
    end
  end

  # Example 4: Multiple mounts for different backends
  defmodule MultiBackendRouter do
    use Phoenix.Router
    import Crucible.UI.Router

    # Production experiments
    scope "/experiments" do
      pipe_through [:browser, :require_admin]

      experiment_routes("/",
        backend: MyApp.ProductionBackend,
        root_layout: {MyAppWeb.Layouts, :admin},
        telemetry_prefix: [:my_app, :production, :experiments]
      )
    end

    # Sandbox experiments
    scope "/sandbox" do
      pipe_through [:browser, :require_authenticated]

      experiment_routes("/",
        backend: MyApp.SandboxBackend,
        root_layout: {MyAppWeb.Layouts, :app},
        telemetry_prefix: [:my_app, :sandbox, :experiments]
      )
    end
  end

  # Example 5: Nested under other routes
  defmodule NestedRouter do
    use Phoenix.Router
    import Crucible.UI.Router

    scope "/admin", MyAppWeb.Admin do
      pipe_through [:browser, :require_admin]

      # Other admin routes
      live "/users", UserLive.Index
      live "/settings", SettingsLive

      # Mount Crucible UI under /admin/experiments
      scope "/experiments" do
        experiment_routes("/",
          backend: Example.CrucibleBackend,
          root_layout: {MyAppWeb.Layouts, :admin},
          on_mount: [MyAppWeb.RequireAdmin, MyAppWeb.LoadAdminUser]
        )
      end
    end
  end

  # Example 6: With custom PubSub configuration
  defmodule CustomPubSubRouter do
    use Phoenix.Router
    import Crucible.UI.Router

    scope "/" do
      pipe_through :browser

      experiment_routes("/",
        backend: Example.CrucibleBackend,
        pubsub: MyApp.CustomPubSub,
        telemetry_prefix: [:my_app, :experiments]
      )
    end
  end

  # Example 7: Full configuration with all options
  defmodule FullConfigRouter do
    use Phoenix.Router
    import Crucible.UI.Router

    scope "/ml" do
      pipe_through [:browser, :require_researcher]

      experiment_routes("/experiments",
        backend: MyApp.MLBackend,
        on_mount: [
          MyAppWeb.RequireResearcher,
          MyAppWeb.LoadProject,
          MyAppWeb.TrackActivity
        ],
        root_layout: {MyAppWeb.Layouts, :research},
        telemetry_prefix: [:my_app, :ml, :experiments],
        pubsub: MyApp.ResearchPubSub
      )
    end
  end
end
