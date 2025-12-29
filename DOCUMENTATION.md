# Crucible UI Documentation Index

Complete documentation for the Crucible UI composable experiment dashboard library.

## Quick Links

- [README.md](README.md) - Main documentation, quick start guide
- [CHANGELOG.md](CHANGELOG.md) - Version history and migration guides
- [Example App](example/) - Comprehensive integration examples

## Core Documentation

### 1. Getting Started

- **Installation**: See [README.md](README.md#installation)
- **Quick Start**: See [README.md](README.md#quick-start)
- **Architecture**: See [README.md](README.md#architecture)

### 2. Backend Behaviour

The `Crucible.UI.Backend` behaviour is the heart of the composable architecture.

**Module**: `lib/crucible/ui/backend.ex`

**Required Callbacks**: 15 total
- 8 for experiment management
- 4 for run management
- 3 for telemetry and statistics

**Optional Callbacks**: 1
- `pubsub_topic/2` - Custom PubSub topic names

**Documentation**:
- Full behaviour specification: See [Backend module docs](lib/crucible/ui/backend.ex)
- Complete implementation example: See [README.md](README.md#complete-backend-implementation-example)
- In-memory backend example: See [example/backend_example.ex](example/backend_example.ex)

### 3. Router Integration

**Module**: `lib/crucible/ui/router.ex`

**Macro**: `experiment_routes/2`

**Options**:
- `:backend` (required) - Module implementing `Crucible.UI.Backend`
- `:on_mount` - LiveView authentication hooks
- `:root_layout` - Layout tuple
- `:telemetry_prefix` - Telemetry event prefix
- `:pubsub` - PubSub module

**Routes Created**:
- `GET /` - Dashboard
- `GET /experiments` - Experiment list
- `GET /experiments/:id` - Experiment details
- `GET /runs/:id` - Run details
- `GET /statistics` - Statistics
- `GET /ensemble` - Ensemble voting
- `GET /hedging` - Request hedging

**Examples**: See [example/router_example.ex](example/router_example.ex)

### 4. Components

**Module**: `lib/crucible/ui/components.ex`

**Total Components**: 12

#### Layout & Navigation (2)
- `header/1` - Page headers with subtitle and actions
- `back/1` - Back navigation links

#### Data Display (4)
- `stat_card/1` - Metric display cards
- `status_badge/1` - Status indicators (5 states)
- `list/1` - Definition lists
- `table/1` - Data tables with streaming support

#### Interaction (2)
- `button/1` - Action buttons
- `modal/1` - Modal dialogs

#### Utilities (1)
- `icon/1` - Heroicons

Plus inherited from Phoenix.Component:
- `link/1`, `input/1`, `error/1`

**Documentation**:
- Component catalog: See [README.md](README.md#available-components-12-total)
- Module documentation: See [Components module](lib/crucible/ui/components.ex)
- Usage examples: See [example/custom_live_example.ex](example/custom_live_example.ex)

### 5. LiveViews

All LiveViews are host-agnostic and located in `lib/crucible/ui/live/`:

#### Core Views
- **DashboardLive** - System overview with stats
  - Real-time updates via PubSub
  - Aggregated metrics
  - Recent experiments and runs

- **ExperimentListLive** - Experiment index
  - Streaming support
  - Create/delete operations
  - Status filtering

- **ExperimentShowLive** - Experiment details
  - Run management
  - Start/complete actions
  - Real-time run updates

- **RunShowLive** - Run details
  - Real-time telemetry streaming
  - Metrics and hyperparameters
  - Event history

#### Placeholder Views
- **StatisticsLive** - Statistics visualization (placeholder)
- **EnsembleLive** - Ensemble voting (placeholder)
- **HedgingLive** - Request hedging (placeholder)

**Features**:
- Backend dependency injection
- PubSub real-time updates
- Support for both Ecto structs and plain maps
- Comprehensive error handling

### 6. Default Backend

**Module**: `lib/crucible_ui/default_backend.ex`

The default backend wraps existing `CrucibleUI` contexts for backward compatibility.

**Purpose**: Allows the CrucibleUI standalone app to work with the new composable architecture.

**PubSub Topics**:
- `experiments:list`
- `runs:list`
- `experiment:{id}`
- `experiment:{id}:runs`
- `run:{id}`
- `run:{id}:telemetry`

## Examples

### Complete Working Examples

The `example/` directory contains:

1. **backend_example.ex** - In-memory backend implementation
   - Uses ETS tables
   - No database required
   - Includes seed data
   - Perfect for testing

2. **router_example.ex** - 7 router configuration examples
   - Basic mounting
   - Authentication
   - Custom layouts
   - Multiple backends
   - Nested routes
   - Custom PubSub
   - Full configuration

3. **custom_live_example.ex** - 5 LiveView examples
   - Custom dashboard
   - Experiment list
   - Experiment details
   - Modal usage
   - Combined components

### Integration Patterns

See [README.md](README.md#example-apps) for:
- Using the default backend
- Custom integration
- CNS UI integration example

## Migration Guide

**From v0.1.x to v0.2.0**: See [CHANGELOG.md](CHANGELOG.md#migration-guide-from-v01x)

### Breaking Changes
1. Router: Use `experiment_routes/2` macro
2. Components: Import from `Crucible.UI.Components`
3. LiveViews: Use composable LiveViews
4. Backend: Implement `Crucible.UI.Backend` behaviour

### What Stays the Same
- Database schema
- Context modules
- REST API
- Telemetry events
- PubSub messages

## Type Specifications

All public functions have `@spec` annotations:

- **Backend behaviour**: Full type specifications for all 15 callbacks
- **DefaultBackend**: Complete `@spec` coverage
- **Components**: Attribute specifications via `attr/2` and `slot/2`

## Design Principles

1. **Host-Agnostic** - No app-specific dependencies
2. **Dependency Injection** - Backend passed via session
3. **Type Safety** - Comprehensive behaviours and typespecs
4. **Real-time** - PubSub integration throughout
5. **Flexible** - Accepts both Ecto structs and plain maps

## Testing

**Test Coverage**: 93 tests, 0 failures

**Quality Gates**:
```bash
mix compile --warnings-as-errors  # ✓ Passes
mix format --check-formatted      # ✓ Passes
mix test                          # ✓ 93 tests, 0 failures
mix dialyzer                      # ✓ 4 minor warnings (acceptable)
```

## Development Workflow

```bash
# Install dependencies
mix deps.get

# Setup database
mix ecto.setup

# Run tests
mix test

# Run server
mix phx.server

# Quality checks
mix compile --warnings-as-errors
mix format --check-formatted
mix credo --strict
mix dialyzer
```

## Contributing

See [README.md](README.md#contributing) for contribution guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- GitHub Issues: https://github.com/North-Shore-AI/crucible_ui/issues
- Main Project: https://github.com/North-Shore-AI
- Documentation: This file and [README.md](README.md)
