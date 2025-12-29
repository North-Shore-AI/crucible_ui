# Crucible UI

Composable experiment dashboard UI components for Phoenix LiveView applications.

**Version:** 0.2.0
**License:** MIT

## Overview

Crucible UI is a feature module that provides complete experiment dashboard functionality for ML reliability research. It follows the composable Phoenix architecture pattern, allowing you to mount fully-functional experiment dashboards in any Phoenix LiveView application with minimal integration effort.

### Key Features

- **Host-Agnostic LiveViews**: No dependencies on specific app modules
- **One-Line Mounting**: `experiment_routes/2` macro integrates complete dashboard
- **Pluggable Backend**: `Crucible.UI.Backend` behaviour for custom data layers
- **Real-Time Updates**: PubSub integration for live experiment tracking
- **Composable Components**: Reusable UI elements for custom views
- **Type-Safe**: Comprehensive `@behaviour` and typespecs

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:crucible_ui, "~> 0.2.0"}
  ]
end
```

Or use a path dependency for local development:

```elixir
def deps do
  [
    {:crucible_ui, path: "../crucible_ui"}
  ]
end
```

## Quick Start

### 1. Implement the Backend Behaviour

Create a module that implements `Crucible.UI.Backend`:

```elixir
defmodule MyApp.CrucibleBackend do
  @behaviour Crucible.UI.Backend

  alias MyApp.{Experiments, Runs, Telemetry}

  @impl true
  def list_experiments(_opts \\ []) do
    experiments = Experiments.list_all()
    {:ok, experiments}
  end

  @impl true
  def get_experiment(id) do
    case Experiments.get(id) do
      nil -> {:error, :not_found}
      experiment -> {:ok, experiment}
    end
  end

  @impl true
  def get_experiment_with_associations(id) do
    case Experiments.get_with_runs(id) do
      nil -> {:error, :not_found}
      experiment -> {:ok, experiment}
    end
  end

  # ... implement remaining callbacks (see Behaviour section below)
end
```

### 2. Mount in Your Router

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import Crucible.UI.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/experiments" do
    pipe_through [:browser, :require_authenticated]

    experiment_routes "/",
      backend: MyApp.CrucibleBackend,
      on_mount: [MyAppWeb.RequireAuth],
      root_layout: {MyAppWeb.Layouts, :app},
      telemetry_prefix: [:my_app, :experiments]
  end
end
```

### 3. Done!

Your app now has:

- Dashboard at `/experiments`
- Experiment list at `/experiments/experiments`
- Experiment details at `/experiments/experiments/:id`
- Run details at `/experiments/runs/:id`
- Statistics, ensemble, and hedging visualizations

## Backend Behaviour

The `Crucible.UI.Backend` behaviour defines the interface between the UI and your data layer. Implement all required callbacks to integrate with your existing data layer.

### Required Callbacks (15)

#### Experiment Management

```elixir
# List all experiments with optional filtering
@callback list_experiments(opts :: keyword()) :: {:ok, [experiment()]} | {:error, term()}
# Options: :status, :limit, :order

# Get a single experiment
@callback get_experiment(id :: term()) :: {:ok, experiment()} | {:error, term()}

# Get experiment with preloaded runs and results
@callback get_experiment_with_associations(id :: term()) :: {:ok, experiment()} | {:error, term()}

# Create a new experiment
@callback create_experiment(attrs :: map()) :: {:ok, experiment()} | {:error, term()}

# Update an experiment
@callback update_experiment(id :: term(), attrs :: map()) :: {:ok, experiment()} | {:error, term()}

# Delete an experiment
@callback delete_experiment(id :: term()) :: {:ok, experiment()} | {:error, term()}

# Start an experiment (status: pending -> running)
@callback start_experiment(id :: term()) :: {:ok, experiment()} | {:error, term()}

# Complete an experiment (status: running -> completed)
@callback complete_experiment(id :: term()) :: {:ok, experiment()} | {:error, term()}
```

#### Run Management

```elixir
# List runs for an experiment
@callback list_runs(experiment_id :: term(), opts :: keyword()) :: {:ok, [run()]} | {:error, term()}
# Options: :status, :limit

# Get a single run with associations (experiment, telemetry events)
@callback get_run(id :: term()) :: {:ok, run()} | {:error, term()}

# Start a run (status: pending -> running)
@callback start_run(id :: term()) :: {:ok, run()} | {:error, term()}

# Complete a run (status: running -> completed)
@callback complete_run(id :: term()) :: {:ok, run()} | {:error, term()}
```

#### Telemetry & Statistics

```elixir
# List telemetry events for a run
@callback list_telemetry_events(run_id :: term(), opts :: keyword()) :: {:ok, [event()]} | {:error, term()}
# Options: :limit (default 100), :event_type

# Get statistics for an experiment or run
@callback get_statistics(id :: term()) :: {:ok, statistics()} | {:error, term()}

# Get system-wide statistics for dashboard
@callback get_system_statistics() :: {:ok, map()} | {:error, term()}
```

### Optional Callbacks

```elixir
# Custom PubSub topic names (defaults provided)
@callback pubsub_topic(resource :: atom(), id :: term()) :: String.t()
# Resources: :experiments_list, :runs_list, :experiment, :experiment_runs, :run, :run_telemetry
```

### Complete Backend Implementation Example

```elixir
defmodule MyApp.CrucibleBackend do
  @behaviour Crucible.UI.Backend

  alias MyApp.{Repo, Experiments, Runs, Telemetry}
  import Ecto.Query

  # Experiment callbacks
  @impl true
  def list_experiments(opts \\ []) do
    query = from(e in Experiments.Experiment)

    query =
      if status = opts[:status] do
        where(query, [e], e.status == ^status)
      else
        query
      end

    query =
      if limit = opts[:limit] do
        limit(query, ^limit)
      else
        query
      end

    query = order_by(query, [e], desc: e.inserted_at)

    {:ok, Repo.all(query)}
  end

  @impl true
  def get_experiment(id) do
    case Repo.get(Experiments.Experiment, id) do
      nil -> {:error, :not_found}
      experiment -> {:ok, experiment}
    end
  end

  @impl true
  def get_experiment_with_associations(id) do
    case Repo.get(Experiments.Experiment, id) do
      nil ->
        {:error, :not_found}

      experiment ->
        experiment = Repo.preload(experiment, [:runs, :statistical_results])
        {:ok, experiment}
    end
  end

  @impl true
  def create_experiment(attrs) do
    %Experiments.Experiment{}
    |> Experiments.Experiment.changeset(attrs)
    |> Repo.insert()
  end

  @impl true
  def update_experiment(id, attrs) do
    case get_experiment(id) do
      {:ok, experiment} ->
        experiment
        |> Experiments.Experiment.changeset(attrs)
        |> Repo.update()

      error -> error
    end
  end

  @impl true
  def delete_experiment(id) do
    case get_experiment(id) do
      {:ok, experiment} -> Repo.delete(experiment)
      error -> error
    end
  end

  @impl true
  def start_experiment(id) do
    update_experiment(id, %{
      status: "running",
      started_at: DateTime.utc_now()
    })
  end

  @impl true
  def complete_experiment(id) do
    update_experiment(id, %{
      status: "completed",
      completed_at: DateTime.utc_now()
    })
  end

  # Run callbacks
  @impl true
  def list_runs(experiment_id, opts \\ []) do
    query = from(r in Runs.Run, where: r.experiment_id == ^experiment_id)

    query =
      if status = opts[:status] do
        where(query, [r], r.status == ^status)
      else
        query
      end

    query = order_by(query, [r], desc: r.inserted_at)

    {:ok, Repo.all(query)}
  end

  @impl true
  def get_run(id) do
    case Repo.get(Runs.Run, id) do
      nil -> {:error, :not_found}
      run -> {:ok, Repo.preload(run, [:experiment, :statistical_results])}
    end
  end

  @impl true
  def start_run(id) do
    case get_run(id) do
      {:ok, run} ->
        run
        |> Runs.Run.changeset(%{status: "running", started_at: DateTime.utc_now()})
        |> Repo.update()

      error -> error
    end
  end

  @impl true
  def complete_run(id) do
    case get_run(id) do
      {:ok, run} ->
        run
        |> Runs.Run.changeset(%{status: "completed", completed_at: DateTime.utc_now()})
        |> Repo.update()

      error -> error
    end
  end

  # Telemetry & Statistics callbacks
  @impl true
  def list_telemetry_events(run_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    query = from(e in Telemetry.Event,
      where: e.run_id == ^run_id,
      order_by: [desc: e.recorded_at],
      limit: ^limit
    )

    query =
      if event_type = opts[:event_type] do
        where(query, [e], e.event_type == ^event_type)
      else
        query
      end

    {:ok, Repo.all(query)}
  end

  @impl true
  def get_statistics(id) do
    # Implement based on your statistics schema
    {:ok, %{}}
  end

  @impl true
  def get_system_statistics do
    experiments = Repo.all(Experiments.Experiment)
    runs = Repo.all(Runs.Run)

    {:ok, %{
      total_experiments: length(experiments),
      running_experiments: Enum.count(experiments, &(&1.status == "running")),
      completed_experiments: Enum.count(experiments, &(&1.status == "completed")),
      total_runs: length(runs),
      running_runs: Enum.count(runs, &(&1.status == "running")),
      significant_results: 0,  # Compute from your statistics
      recent_experiments: Enum.take(experiments, 5),
      recent_runs: Enum.take(runs, 5)
    }}
  end

  # Optional: Custom PubSub topics
  @impl true
  def pubsub_topic(:experiments_list, _id), do: "my_app:experiments:list"
  def pubsub_topic(:experiment, id), do: "my_app:experiment:#{id}"
  def pubsub_topic(:experiment_runs, id), do: "my_app:experiment:#{id}:runs"
  def pubsub_topic(:run, id), do: "my_app:run:#{id}"
  def pubsub_topic(:run_telemetry, id), do: "my_app:run:#{id}:telemetry"
  def pubsub_topic(_, _), do: "my_app:updates"
end
```

### Expected Data Structures

Experiments, runs, and events can be Ecto structs or plain maps with these fields:

**Experiment:**
```elixir
%{
  id: 1,
  name: "My Experiment",
  description: "Test description",
  status: "running",  # "pending" | "running" | "completed" | "failed" | "cancelled"
  config: %{...},
  started_at: ~U[2025-12-06 12:00:00Z],
  completed_at: nil,
  runs: [...],  # for get_experiment_with_associations
  statistical_results: [...],
  inserted_at: ~U[2025-12-06 11:00:00Z],
  updated_at: ~U[2025-12-06 12:00:00Z]
}
```

**Run:**
```elixir
%{
  id: 1,
  experiment_id: 1,
  experiment: %{...},  # for get_run
  status: "running",
  started_at: ~U[2025-12-06 12:00:00Z],
  completed_at: nil,
  checkpoint_path: "/path/to/checkpoint",
  metrics: %{accuracy: 0.95},
  hyperparameters: %{learning_rate: 0.001},
  statistical_results: [...]
}
```

**Telemetry Event:**
```elixir
%{
  id: 1,
  run_id: 1,
  event_type: "metric_update",
  data: %{loss: 0.123},
  recorded_at: ~U[2025-12-06 12:00:00Z]
}
```

**System Statistics:**
```elixir
%{
  total_experiments: 42,
  running_experiments: 3,
  completed_experiments: 38,
  total_runs: 156,
  running_runs: 5,
  significant_results: 23,
  recent_experiments: [...],  # up to 5
  recent_runs: [...]  # up to 5
}
```

## Router Options

The `experiment_routes/2` macro accepts:

- **`:backend`** (required) - Module implementing `Crucible.UI.Backend`
- **`:on_mount`** - List of LiveView mount hooks for auth/authorization
- **`:root_layout`** - Root layout tuple `{Module, :template}`
- **`:telemetry_prefix`** - Telemetry event prefix (default: `[:crucible, :ui]`)
- **`:pubsub`** - PubSub module (default: inferred from backend module name)

Example with all options:

```elixir
experiment_routes "/experiments",
  backend: MyApp.ExperimentBackend,
  on_mount: [MyAppWeb.RequireAuth, MyAppWeb.LoadUser],
  root_layout: {MyAppWeb.Layouts, :dashboard},
  telemetry_prefix: [:my_app, :crucible],
  pubsub: MyApp.PubSub
```

## Components

Use Crucible UI components in your own LiveViews:

```elixir
defmodule MyAppWeb.CustomLive do
  use Phoenix.LiveView
  import Crucible.UI.Components

  def render(assigns) do
    ~H"""
    <.header>
      My Custom View
      <:subtitle>Using Crucible components</:subtitle>
      <:actions>
        <.button phx-click="refresh">Refresh</.button>
      </:actions>
    </.header>

    <div class="grid grid-cols-3 gap-4">
      <.stat_card
        icon="hero-beaker"
        label="Total Experiments"
        value={@experiment_count}
      />
      <.stat_card
        icon="hero-play"
        label="Running"
        value={@running_count}
        icon_class="text-green-400"
      />
    </div>

    <.table id="experiments" rows={@experiments}>
      <:col :let={exp} label="Name"><%= exp.name %></:col>
      <:col :let={exp} label="Status">
        <.status_badge status={exp.status} />
      </:col>
    </.table>
    """
  end
end
```

### Available Components (12 total)

#### Layout & Navigation

- **`header/1`** - Page headers with optional subtitle and action buttons
  - Slots: `inner_block` (title), `subtitle`, `actions`
  - Example: `<.header>Title<:subtitle>Description</:subtitle><:actions><.button>Action</.button></:actions></.header>`

- **`back/1`** - Back navigation link with icon
  - Attrs: `navigate` (required)
  - Example: `<.back navigate={~p"/experiments"}>Back to experiments</.back>`

#### Data Display

- **`stat_card/1`** - Metric display cards with icon
  - Attrs: `icon`, `label`, `value`, `icon_class` (optional), `class` (optional)
  - Example: `<.stat_card icon="hero-beaker" label="Total" value={42} icon_class="text-blue-400" />`

- **`status_badge/1`** - Colored status indicators
  - Attrs: `status` (required), `class` (optional)
  - Statuses: `"pending"` (gray), `"running"` (blue), `"completed"` (green), `"failed"` (red), `"cancelled"` (yellow)
  - Example: `<.status_badge status="running" />`

- **`list/1`** - Definition lists for key-value pairs
  - Slots: `item` (with `title` attr)
  - Example: `<.list><:item title="Name">John</:item><:item title="Status">Active</:item></.list>`

- **`table/1`** - Sortable data tables with streaming support
  - Attrs: `id` (required), `rows` (required), `row_click` (optional), `row_id` (optional)
  - Slots: `col` (with `label` attr), `action` (with optional `label` attr)
  - Supports LiveView streams for efficient updates
  - Example: `<.table id="items" rows={@streams.items}><:col :let={{_id, item}} label="Name"><%= item.name %></:col></.table>`

#### Interaction

- **`button/1`** - Primary action button
  - Attrs: `type` (optional), `class` (optional), plus all standard HTML button attrs
  - Example: `<.button phx-click="save">Save</.button>`

- **`modal/1`** - Modal dialog with backdrop
  - Attrs: `id` (required), `show` (boolean), `on_cancel` (JS command)
  - Includes close button and click-away to dismiss
  - Example: `<.modal id="confirm" show on_cancel={JS.patch(~p"/back")}><p>Content</p></.modal>`

#### Utilities

- **`icon/1`** - Heroicon display
  - Attrs: `name` (required, e.g., `"hero-beaker"`), `class` (optional)
  - Example: `<.icon name="hero-check-circle" class="h-5 w-5 text-green-500" />`

Note: Phoenix.Component's `link/1`, `input/1`, and `error/1` are also available when you import `Crucible.UI.Components`.

## Example Apps

### Using the Default Backend

For existing Crucible UI apps, use the included `CrucibleUI.DefaultBackend`:

```elixir
# In your router
experiment_routes "/",
  backend: CrucibleUI.DefaultBackend,
  root_layout: {CrucibleUIWeb.Layouts, :root},
  pubsub: CrucibleUI.PubSub
```

This wraps the existing `CrucibleUI.Experiments`, `CrucibleUI.Runs`, and `CrucibleUI.Telemetry` contexts.

### Custom Integration

For apps with different data layers (e.g., CNS UI, other research tools):

```elixir
defmodule CnsUi.ExperimentBackend do
  @behaviour Crucible.UI.Backend

  alias CnsUi.Research.{Experiments, Runs}

  # Map your existing functions to the backend interface
  def list_experiments(_opts), do: {:ok, Experiments.all()}
  def get_experiment(id), do: Experiments.find(id)
  # ... etc
end

# In router
experiment_routes "/experiments",
  backend: CnsUi.ExperimentBackend,
  on_mount: [CnsUiWeb.RequireResearcher],
  root_layout: {CnsUiWeb.Layouts, :app}
```

## Architecture

### Directory Structure

```
lib/
├── crucible/ui/                    # Feature module (composable)
│   ├── backend.ex                  # Behaviour definition
│   ├── router.ex                   # Router macro
│   ├── components.ex               # Reusable UI components
│   └── live/                       # Host-agnostic LiveViews
│       ├── dashboard_live.ex
│       ├── experiment_list_live.ex
│       ├── experiment_show_live.ex
│       ├── run_show_live.ex
│       ├── statistics_live.ex
│       ├── ensemble_live.ex
│       └── hedging_live.ex
├── crucible_ui/                    # Original app contexts
│   ├── default_backend.ex          # Adapter for existing app
│   ├── experiments.ex
│   ├── runs.ex
│   └── telemetry.ex
└── crucible_ui_web/                # Original app web layer
    ├── router.ex                   # Now uses experiment_routes macro
    ├── endpoint.ex
    └── ...
```

### Design Principles

1. **Host-Agnostic**: LiveViews use `Phoenix.LiveView` directly (not `use MyAppWeb, :live_view`)
2. **Dependency Injection**: Backend passed via session, not hard-coded
3. **Layout Flexibility**: Accepts host app's layout via `root_layout` option
4. **PubSub Abstraction**: Topics configurable per backend
5. **Type Safety**: Comprehensive behaviours and typespecs

## Development

```bash
# Install dependencies
mix deps.get

# Setup database
mix ecto.setup

# Run tests
mix test

# Run server
mix phx.server
```

## Testing

```bash
# All tests
mix test

# With coverage
mix test --cover

# Quality gates
mix compile --warnings-as-errors
mix format --check-formatted
mix credo --strict
mix dialyzer
```

## Roadmap

- [ ] Example Phoenix app in `example/` directory
- [ ] Tests for backend behaviour compliance
- [ ] Tests for router macro
- [ ] Form components (currently host-specific placeholders)
- [ ] Advanced statistics visualizations
- [ ] Ensemble voting implementation
- [ ] Request hedging visualization
- [ ] Asset bundling strategy (CSS/JS hooks)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run quality gates (`mix test && mix format && mix credo`)
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by `phoenix_live_dashboard`, `oban_web`, and `ash_admin`
- Part of the North-Shore-AI ML reliability research ecosystem
- Built with Phoenix LiveView 0.20+

## Links

- [GitHub Repository](https://github.com/North-Shore-AI/crucible_ui)
- [Changelog](CHANGELOG.md)
- [North-Shore-AI Project](https://github.com/North-Shore-AI)
- [Crucible Framework](https://github.com/North-Shore-AI/crucible_framework)
