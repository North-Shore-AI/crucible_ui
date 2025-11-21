defmodule CrucibleUI.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/North-Shore-AI/crucible_ui"

  def project do
    [
      app: :crucible_ui,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),

      # Hex package
      package: package(),
      description: description(),

      # Docs
      name: "Crucible UI",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),

      # Dialyzer
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix, :ex_unit]
      ],

      # Test coverage
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      mod: {CrucibleUI.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix
      {:phoenix, "~> 1.7.10"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.1"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.2"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:plug_cowboy, "~> 2.5"},
      {:bandit, "~> 1.0"},

      # Crucible ecosystem
      # {:tinkex, "~> 0.1.0"},
      # {:crucible_telemetry, "~> 0.1.0"},

      # Development & Testing
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:ex_machina, "~> 2.7", only: :test},
      {:faker, "~> 0.17", only: :test},

      # Optional features
      {:heroicons, "~> 0.5"},
      {:ecto_enum, "~> 1.4"}
    ]
  end

  defp package do
    [
      name: "crucible_ui",
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      maintainers: ["North-Shore-AI"]
    ]
  end

  defp description do
    """
    Phoenix LiveView Dashboard for ML Reliability Research.
    Real-time monitoring and management for machine learning experiments
    within the Crucible ML reliability stack.
    """
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "LICENSE"
      ],
      groups_for_modules: [
        Contexts: [
          CrucibleUI.Experiments,
          CrucibleUI.Runs,
          CrucibleUI.Telemetry,
          CrucibleUI.Models,
          CrucibleUI.Statistics
        ],
        Schemas: [
          CrucibleUI.Experiments.Experiment,
          CrucibleUI.Runs.Run,
          CrucibleUI.Telemetry.Event,
          CrucibleUI.Models.Model,
          CrucibleUI.Statistics.Result
        ],
        LiveViews: [
          CrucibleUIWeb.DashboardLive,
          CrucibleUIWeb.ExperimentLive.Index,
          CrucibleUIWeb.ExperimentLive.Show,
          CrucibleUIWeb.RunLive.Show,
          CrucibleUIWeb.StatisticsLive,
          CrucibleUIWeb.EnsembleLive,
          CrucibleUIWeb.HedgingLive
        ],
        Components: [
          CrucibleUIWeb.Components.Charts,
          CrucibleUIWeb.Components.Metrics,
          CrucibleUIWeb.Components.Tables
        ],
        Controllers: [
          CrucibleUIWeb.API.ExperimentController,
          CrucibleUIWeb.API.TelemetryController,
          CrucibleUIWeb.API.ModelController
        ]
      ]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
