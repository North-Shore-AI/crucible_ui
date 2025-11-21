# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

import Config

config :crucible_ui,
  ecto_repos: [CrucibleUI.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :crucible_ui, CrucibleUIWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: CrucibleUIWeb.ErrorHTML, json: CrucibleUIWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: CrucibleUI.PubSub,
  live_view: [signing_salt: "crucible_ui_salt"]

# Configures the mailer
config :crucible_ui, CrucibleUI.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Crucible UI specific configuration
config :crucible_ui,
  # Telemetry integration
  telemetry_source: :crucible_telemetry,
  # Dashboard refresh interval (ms)
  refresh_interval: 1000,
  # Maximum events to display in timeline
  max_timeline_events: 1000,
  # Enable/disable specific features
  features: [
    experiments: true,
    ensembles: true,
    hedging: true,
    statistical_tests: true
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
