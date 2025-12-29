# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-12-06

### Changed
- **BREAKING:** Restructured as composable feature library following Phoenix best practices
- LiveViews are now host-agnostic (no app-specific dependencies)
- Router macro `experiment_routes/2` for one-line mounting
- All existing app functionality preserved via `CrucibleUI.DefaultBackend`

### Added
- `Crucible.UI.Backend` behaviour for pluggable data layers (15 required callbacks)
- `Crucible.UI.Router` macro for composable routing
- Host-agnostic LiveViews in `lib/crucible/ui/live/`:
  - `DashboardLive` - System overview with real-time stats
  - `ExperimentListLive` - Experiment index with streaming
  - `ExperimentShowLive` - Experiment details with run management
  - `RunShowLive` - Run details with real-time telemetry
  - `StatisticsLive` - Statistics visualization (placeholder)
  - `EnsembleLive` - Ensemble voting (placeholder)
  - `HedgingLive` - Request hedging (placeholder)
- `Crucible.UI.Components` - 12 reusable UI components:
  - `stat_card/1` - Metric display cards
  - `status_badge/1` - Status indicators
  - `header/1` - Page headers with actions
  - `list/1` - Definition lists
  - `table/1` - Sortable data tables with streaming
  - `modal/1` - Modal dialogs
  - `button/1`, `back/1`, `icon/1` - Basic UI elements
- `CrucibleUI.DefaultBackend` - Adapter for existing contexts
- Comprehensive inline documentation with examples
- Complete Backend implementation example in README

### Fixed
- Support for both Ecto structs and plain maps in LiveViews
- Proper PubSub topic inference from backend modules
- Component naming conflicts with Phoenix.Component

### Migration Guide from v0.1.x

#### For Existing CrucibleUI App Users

If you're currently using CrucibleUI as a standalone app, **no changes required**. The app now uses `CrucibleUI.DefaultBackend` internally and functions identically.

To verify, check your `lib/crucible_ui_web/router.ex`:

```elixir
# Old (v0.1.x) - still works but deprecated
live "/", CrucibleUIWeb.DashboardLive, :index

# New (v0.2.0) - recommended
import Crucible.UI.Router

experiment_routes "/",
  backend: CrucibleUI.DefaultBackend,
  root_layout: {CrucibleUIWeb.Layouts, :root},
  pubsub: CrucibleUI.PubSub
```

#### For Apps Using CrucibleUI as a Dependency

**Before (v0.1.x):** You couldn't use CrucibleUI in other apps.

**After (v0.2.0):** Follow these steps:

1. **Implement the Backend behaviour:**

```elixir
defmodule MyApp.CrucibleBackend do
  @behaviour Crucible.UI.Backend

  # Implement all 15 required callbacks
  # See README "Complete Backend Implementation Example"
end
```

2. **Update your router:**

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import Crucible.UI.Router

  scope "/experiments" do
    pipe_through [:browser, :require_authenticated]

    experiment_routes "/",
      backend: MyApp.CrucibleBackend,
      on_mount: [MyAppWeb.RequireAuth],
      root_layout: {MyAppWeb.Layouts, :app}
  end
end
```

3. **Use components in your LiveViews:**

```elixir
defmodule MyAppWeb.CustomLive do
  use Phoenix.LiveView
  import Crucible.UI.Components

  def render(assigns) do
    ~H"""
    <.stat_card icon="hero-beaker" label="Experiments" value={@count} />
    <.status_badge status="running" />
    """
  end
end
```

#### Breaking Changes Summary

1. **Router:** Use `experiment_routes/2` macro instead of manually defining LiveView routes
2. **Components:** Import from `Crucible.UI.Components` instead of app-specific component modules
3. **LiveViews:** Use composable LiveViews from `Crucible.UI.*Live` instead of `CrucibleUIWeb.*Live`
4. **Backend:** Implement `Crucible.UI.Backend` behaviour for custom data layers

#### What Stays the Same

- Database schema (migrations unchanged)
- Context modules (`CrucibleUI.Experiments`, `CrucibleUI.Runs`, etc.)
- REST API endpoints
- Telemetry events
- PubSub messages

## [0.1.0] - 2024-11-21

### Added
- Initial standalone Phoenix application
- Experiment management LiveViews
- Real-time telemetry streaming
- Statistical analysis dashboards
- Ensemble voting visualization
- Request hedging visualization
- REST API for experiments, runs, and telemetry
- PostgreSQL backend with Ecto

[0.2.0]: https://github.com/North-Shore-AI/crucible_ui/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/North-Shore-AI/crucible_ui/releases/tag/v0.1.0
