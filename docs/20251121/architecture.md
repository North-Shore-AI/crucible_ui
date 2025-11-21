# Crucible UI Architecture

This document describes the technical architecture of Crucible UI, a Phoenix LiveView dashboard for ML reliability research.

## Overview

Crucible UI follows a layered architecture pattern optimized for real-time updates and scalability:

```
+---------------------------------------------------+
|                  Browser Client                    |
|  (LiveView WebSocket + REST API)                  |
+---------------------------------------------------+
                        |
+---------------------------------------------------+
|              Phoenix Endpoint Layer               |
|  Router | Plugs | WebSocket | REST Controllers    |
+---------------------------------------------------+
                        |
+---------------------------------------------------+
|              LiveView Component Layer             |
|  Pages | Components | Hooks | Events              |
+---------------------------------------------------+
                        |
+---------------------------------------------------+
|              Business Logic Layer                 |
|  Contexts | Services | Validators                 |
+---------------------------------------------------+
                        |
+---------------------------------------------------+
|              Data Access Layer                    |
|  Ecto Schemas | Repos | Queries                   |
+---------------------------------------------------+
                        |
+---------------------------------------------------+
|              Integration Layer                    |
|  Crucible Telemetry | PubSub | External APIs      |
+---------------------------------------------------+
```

## LiveView Component Structure

### Page LiveViews

Top-level LiveView modules that handle entire pages:

```
lib/crucible_ui_web/live/
├── dashboard_live.ex          # Home dashboard
├── experiment_live/
│   ├── index.ex               # Experiment list
│   ├── show.ex                # Experiment detail
│   └── form_component.ex      # Create/edit form
├── ensemble_live/
│   ├── index.ex               # Ensemble overview
│   └── show.ex                # Ensemble detail
├── statistical_live/
│   ├── index.ex               # Test results list
│   └── show.ex                # Individual test detail
├── telemetry_live.ex          # Event streaming
└── comparison_live.ex         # Model comparisons
```

### Functional Components

Reusable UI components using `Phoenix.Component`:

```
lib/crucible_ui_web/components/
├── core_components.ex         # Base Phoenix components
├── charts/
│   ├── line_chart.ex          # Time series
│   ├── bar_chart.ex           # Categorical data
│   ├── heatmap.ex             # Correlation matrices
│   └── gauge.ex               # Single metric display
├── tables/
│   ├── data_table.ex          # Sortable/filterable tables
│   └── paginator.ex           # Pagination controls
├── metrics/
│   ├── stat_card.ex           # Single stat display
│   ├── progress_bar.ex        # Progress indicators
│   └── sparkline.ex           # Inline trends
└── forms/
    ├── search_input.ex        # Search with autocomplete
    └── filter_select.ex       # Multi-select filters
```

### LiveView Hooks

JavaScript hooks for Chart.js integration and custom behaviors:

```javascript
// assets/js/hooks/index.js
export const ChartHook = {
  mounted() {
    this.chart = new Chart(this.el, {
      type: this.el.dataset.chartType,
      data: JSON.parse(this.el.dataset.chartData),
      options: JSON.parse(this.el.dataset.chartOptions)
    });
  },
  updated() {
    const newData = JSON.parse(this.el.dataset.chartData);
    this.chart.data = newData;
    this.chart.update();
  },
  destroyed() {
    this.chart.destroy();
  }
};
```

## PubSub for Real-time Updates

### Architecture

```
+------------------+     +------------------+     +------------------+
| Crucible         |     | CrucibleUI       |     | LiveView         |
| Telemetry        | --> | PubSub           | --> | Processes        |
| Events           |     | (Phoenix.PubSub) |     | (Subscribers)    |
+------------------+     +------------------+     +------------------+
```

### Topic Structure

```elixir
# Topic naming conventions
"experiment:#{experiment_id}"           # Single experiment updates
"experiments:list"                       # Experiment list changes
"ensemble:#{ensemble_id}"               # Ensemble voting results
"telemetry:#{experiment_id}"            # Telemetry events
"telemetry:all"                          # All telemetry events
"training:#{run_id}"                     # Training run progress
"comparison:#{comparison_id}"           # Comparison updates
```

### Subscription Pattern

```elixir
defmodule CrucibleUIWeb.ExperimentLive.Show do
  use CrucibleUIWeb, :live_view

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      # Subscribe to experiment-specific updates
      Phoenix.PubSub.subscribe(CrucibleUI.PubSub, "experiment:#{id}")
      Phoenix.PubSub.subscribe(CrucibleUI.PubSub, "telemetry:#{id}")
    end

    experiment = Experiments.get_experiment!(id)
    {:ok, assign(socket, experiment: experiment, events: [])}
  end

  @impl true
  def handle_info({:experiment_updated, experiment}, socket) do
    {:noreply, assign(socket, experiment: experiment)}
  end

  @impl true
  def handle_info({:telemetry_event, event}, socket) do
    events = [event | socket.assigns.events] |> Enum.take(100)
    {:noreply, assign(socket, events: events)}
  end
end
```

### Broadcasting Events

```elixir
defmodule CrucibleUI.Experiments do
  alias Phoenix.PubSub

  def update_experiment(experiment, attrs) do
    experiment
    |> Experiment.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, experiment} ->
        PubSub.broadcast(
          CrucibleUI.PubSub,
          "experiment:#{experiment.id}",
          {:experiment_updated, experiment}
        )
        {:ok, experiment}

      error ->
        error
    end
  end
end
```

## Integration with Crucible Telemetry

### Telemetry Consumer

A GenServer that subscribes to crucible_telemetry events and forwards them to the UI:

```elixir
defmodule CrucibleUI.TelemetryConsumer do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Attach to crucible_telemetry events
    :telemetry.attach_many(
      "crucible-ui-handler",
      [
        [:crucible, :experiment, :start],
        [:crucible, :experiment, :stop],
        [:crucible, :ensemble, :vote],
        [:crucible, :hedging, :request],
        [:crucible, :model, :inference]
      ],
      &__MODULE__.handle_event/4,
      nil
    )

    {:ok, %{}}
  end

  def handle_event(event_name, measurements, metadata, _config) do
    event = %{
      name: event_name,
      measurements: measurements,
      metadata: metadata,
      timestamp: DateTime.utc_now()
    }

    # Persist to database
    CrucibleUI.Telemetry.create_event(event)

    # Broadcast to subscribers
    experiment_id = metadata[:experiment_id]
    if experiment_id do
      Phoenix.PubSub.broadcast(
        CrucibleUI.PubSub,
        "telemetry:#{experiment_id}",
        {:telemetry_event, event}
      )
    end

    Phoenix.PubSub.broadcast(
      CrucibleUI.PubSub,
      "telemetry:all",
      {:telemetry_event, event}
    )
  end
end
```

### Event Storage Backend

Support for multiple storage backends:

```elixir
defmodule CrucibleUI.Telemetry.Storage do
  @callback store_event(event :: map()) :: {:ok, event} | {:error, term()}
  @callback query_events(filters :: keyword()) :: [event]
  @callback aggregate(metric :: atom(), filters :: keyword()) :: number()
end

# ETS backend for development
defmodule CrucibleUI.Telemetry.Storage.ETS do
  @behaviour CrucibleUI.Telemetry.Storage
  # Implementation...
end

# PostgreSQL backend for production
defmodule CrucibleUI.Telemetry.Storage.Postgres do
  @behaviour CrucibleUI.Telemetry.Storage
  # Implementation...
end
```

## Database Schema

### Core Schemas

```elixir
# Experiments
defmodule CrucibleUI.Experiments.Experiment do
  use Ecto.Schema

  schema "experiments" do
    field :name, :string
    field :description, :string
    field :status, Ecto.Enum, values: [:pending, :running, :completed, :failed, :cancelled]
    field :config, :map
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    has_many :runs, CrucibleUI.Experiments.Run
    has_many :results, CrucibleUI.Experiments.Result

    timestamps()
  end
end

# Training Runs
defmodule CrucibleUI.Experiments.Run do
  use Ecto.Schema

  schema "runs" do
    field :status, Ecto.Enum, values: [:pending, :running, :completed, :failed]
    field :hyperparameters, :map
    field :metrics, :map
    field :checkpoint_path, :string

    belongs_to :experiment, CrucibleUI.Experiments.Experiment

    timestamps()
  end
end

# Statistical Results
defmodule CrucibleUI.Statistics.Result do
  use Ecto.Schema

  schema "statistical_results" do
    field :test_type, :string
    field :p_value, :float
    field :effect_size, :float
    field :effect_size_type, :string
    field :confidence_interval, {:array, :float}
    field :sample_sizes, {:array, :integer}
    field :raw_data, :map

    belongs_to :experiment, CrucibleUI.Experiments.Experiment

    timestamps()
  end
end

# Telemetry Events
defmodule CrucibleUI.Telemetry.Event do
  use Ecto.Schema

  schema "telemetry_events" do
    field :event_name, {:array, :string}
    field :measurements, :map
    field :metadata, :map
    field :recorded_at, :utc_datetime

    belongs_to :experiment, CrucibleUI.Experiments.Experiment

    timestamps()
  end
end
```

### Database Indexes

```elixir
# migrations/xxx_create_indexes.exs
defmodule CrucibleUI.Repo.Migrations.CreateIndexes do
  use Ecto.Migration

  def change do
    # Experiment queries
    create index(:experiments, [:status])
    create index(:experiments, [:started_at])

    # Run queries
    create index(:runs, [:experiment_id])
    create index(:runs, [:status])

    # Statistical results
    create index(:statistical_results, [:experiment_id])
    create index(:statistical_results, [:test_type])

    # Telemetry events (time-series optimization)
    create index(:telemetry_events, [:experiment_id])
    create index(:telemetry_events, [:recorded_at])
    create index(:telemetry_events, [:event_name], using: :gin)
  end
end
```

## Asset Pipeline

### Directory Structure

```
assets/
├── css/
│   ├── app.css                # Main stylesheet
│   └── components/            # Component styles
├── js/
│   ├── app.js                 # Main entry point
│   ├── hooks/                 # LiveView hooks
│   │   ├── index.js
│   │   ├── chart_hook.js
│   │   └── copy_hook.js
│   └── vendor/                # Third-party libraries
├── static/
│   ├── images/
│   └── fonts/
├── tailwind.config.js         # Tailwind configuration
└── package.json
```

### Build Configuration

```javascript
// assets/tailwind.config.js
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        crucible: {
          50: '#f0fdfa',
          500: '#0d9488',
          600: '#0891b2',
          700: '#0e7490',
        }
      }
    }
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography")
  ]
}
```

### esbuild Configuration

```elixir
# config/config.exs
config :esbuild,
  version: "0.17.11",
  default: [
    args: ~w(
      js/app.js
      --bundle
      --target=es2017
      --outdir=../priv/static/assets
      --external:/fonts/*
      --external:/images/*
    ),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]
```

## Security Considerations

### Authentication

```elixir
# Using phx.gen.auth
defmodule CrucibleUIWeb.UserAuth do
  # Session-based authentication
  # JWT support for API access
end
```

### Authorization

```elixir
defmodule CrucibleUI.Policy do
  @behaviour Bodyguard.Policy

  def authorize(:view_experiment, user, experiment) do
    user.id == experiment.user_id or user.role == :admin
  end

  def authorize(:delete_experiment, user, _experiment) do
    user.role == :admin
  end
end
```

### API Rate Limiting

```elixir
# Using Hammer for rate limiting
plug Hammer.Plug,
  rate_limit: {"api", 60_000, 100},
  by: {:session, :user_id}
```

## Performance Optimizations

### Database Query Optimization

- Use `Repo.preload` for associations
- Implement cursor-based pagination for large datasets
- Use `Repo.stream` for data exports
- Index frequently queried columns

### LiveView Optimization

- Use `temporary_assigns` for large lists
- Implement virtualization for long tables
- Debounce frequent updates
- Use `push_patch` for navigation

### Caching

```elixir
# Using Cachex for caching
def get_experiment_stats(experiment_id) do
  Cachex.fetch(:stats_cache, experiment_id, fn ->
    {:commit, calculate_stats(experiment_id)}
  end)
end
```

## Monitoring and Observability

### Application Metrics

```elixir
# Using PromEx for Prometheus metrics
defmodule CrucibleUI.PromEx do
  use PromEx, otp_app: :crucible_ui

  @impl true
  def plugins do
    [
      PromEx.Plugins.Application,
      PromEx.Plugins.Beam,
      PromEx.Plugins.Phoenix,
      PromEx.Plugins.Ecto,
      CrucibleUI.PromEx.CustomPlugin
    ]
  end
end
```

### Structured Logging

```elixir
# Using Logger with metadata
Logger.info("Experiment completed",
  experiment_id: experiment.id,
  duration_ms: duration,
  result_count: length(results)
)
```

## Testing Strategy

### Unit Tests

- Context modules (business logic)
- Schema validations
- Helper functions

### Integration Tests

- LiveView rendering and interactions
- PubSub message handling
- Database operations

### End-to-End Tests

- User workflows
- API endpoints
- WebSocket connections

```elixir
# Example LiveView test
defmodule CrucibleUIWeb.ExperimentLiveTest do
  use CrucibleUIWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "displays experiment details", %{conn: conn} do
    experiment = insert(:experiment)
    {:ok, view, html} = live(conn, ~p"/experiments/#{experiment.id}")

    assert html =~ experiment.name
    assert has_element?(view, "#experiment-status", "running")
  end
end
```
