# Crucible UI Example App

This example demonstrates how to integrate Crucible UI into a Phoenix application.

## What This Example Shows

1. **Backend Implementation** - Custom backend using in-memory storage (no database required)
2. **Router Integration** - How to mount Crucible UI routes
3. **Component Usage** - Using Crucible UI components in custom views
4. **Real-time Updates** - PubSub integration for live updates

## Quick Start

Since this is a documentation example (not a runnable Phoenix app), follow these steps to integrate Crucible UI into your own Phoenix application:

### 1. Add Dependency

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:crucible_ui, "~> 0.2.0"}
  ]
end
```

### 2. Implement Backend

Create `lib/my_app/crucible_backend.ex`:

```elixir
defmodule MyApp.CrucibleBackend do
  @behaviour Crucible.UI.Backend

  # See backend_example.ex in this directory for full implementation
end
```

### 3. Update Router

In `lib/my_app_web/router.ex`:

```elixir
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
```

### 4. Use Components

In your LiveViews:

```elixir
defmodule MyAppWeb.DashboardLive do
  use Phoenix.LiveView
  import Crucible.UI.Components

  def render(assigns) do
    ~H"""
    <.header>
      My Dashboard
      <:subtitle>Real-time experiment tracking</:subtitle>
    </.header>

    <.stat_card
      icon="hero-beaker"
      label="Total Experiments"
      value={@experiment_count}
    />
    """
  end
end
```

## Example Files

- `backend_example.ex` - Complete Backend implementation with in-memory storage
- `router_example.ex` - Router configuration examples
- `custom_live_example.ex` - Using Crucible UI components in custom views

## Features Demonstrated

### Backend Implementation
- All 15 required callbacks
- In-memory storage (ETS)
- PubSub broadcasting
- Error handling

### Router Configuration
- Basic mounting
- Authentication hooks
- Custom layouts
- Telemetry prefixes

### Component Usage
- Dashboard layouts
- Stat cards
- Status badges
- Data tables
- Modals

## Key Concepts

### Host-Agnostic Design
Crucible UI components work with any Phoenix app - no dependencies on specific app modules.

### Dependency Injection
Backend is passed via session, allowing different implementations for different apps.

### Type Safety
Comprehensive `@behaviour` and `@spec` ensure compile-time checks.

### Real-time Updates
PubSub integration keeps all views in sync automatically.

## Next Steps

1. Review the example files in this directory
2. Implement your own backend based on `backend_example.ex`
3. Mount routes in your router
4. Start using components in your views

For full documentation, see the [main README](../README.md).
