<div align="center"><img src="assets/crucible_ui.svg" width="400" alt="Crucible UI Logo" /></div>

# Crucible UI

[![Hex.pm](https://img.shields.io/hexpm/v/crucible_ui.svg)](https://hex.pm/packages/crucible_ui)
[![Docs](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/crucible_ui)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**Phoenix LiveView Dashboard for ML Reliability Research**

Crucible UI provides a real-time, interactive dashboard for monitoring and managing machine learning experiments within the Crucible ML reliability stack. Built with Phoenix LiveView, it offers instant updates, rich visualizations, and comprehensive experiment management capabilities.

## Features

### Real-time Experiment Monitoring
- Live experiment status updates via Phoenix PubSub
- Progress tracking with estimated completion times
- Resource utilization metrics (CPU, memory, GPU)
- Automatic refresh without page reloads

### Statistical Test Visualization
- Interactive charts for hypothesis testing results
- Effect size visualizations (Cohen's d, eta-squared)
- P-value distributions and significance indicators
- Confidence interval displays
- Power analysis summaries

### Ensemble Performance Dashboards
- Model voting strategy comparisons (Majority, Weighted, Best Confidence, Unanimous)
- Individual model contribution analysis
- Accuracy and reliability trend charts
- Disagreement heatmaps between models

### Telemetry Event Streaming
- Real-time event feed from crucible_telemetry
- Filterable event timeline
- Event aggregation and summarization
- Custom metric dashboards
- Export to CSV/JSON/Parquet

### Training Run Management
- Create, pause, resume, and cancel training runs
- Hyperparameter configuration interface
- Checkpoint management and restoration
- Multi-run comparison views
- Experiment tagging and organization

### Model Comparison Views
- Side-by-side model performance analysis
- Statistical significance testing between models
- Cost-accuracy trade-off visualizations
- Latency distribution comparisons
- Hedging strategy effectiveness charts

## Screenshots

*Screenshots coming soon*

<!--
![Dashboard Home](docs/screenshots/dashboard_home.png)
![Experiment Detail](docs/screenshots/experiment_detail.png)
![Statistical Results](docs/screenshots/statistical_results.png)
-->

## Installation

### Prerequisites

- Elixir 1.14+
- Erlang/OTP 25+
- PostgreSQL 14+
- Node.js 18+ (for asset compilation)

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/North-Shore-AI/crucible_ui.git
   cd crucible_ui
   ```

2. **Install dependencies:**
   ```bash
   mix deps.get
   ```

3. **Configure the database:**
   ```bash
   # Copy example configuration
   cp config/dev.exs.example config/dev.exs

   # Edit with your database credentials
   # Then create and migrate the database
   mix ecto.setup
   ```

4. **Install Node.js dependencies:**
   ```bash
   cd assets && npm install && cd ..
   ```

5. **Start the Phoenix server:**
   ```bash
   mix phx.server
   ```

6. **Visit the dashboard:**
   Open [http://localhost:4000](http://localhost:4000) in your browser.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgres://localhost/crucible_ui_dev` |
| `SECRET_KEY_BASE` | Phoenix secret key (64+ chars) | Generated |
| `PHX_HOST` | Hostname for the application | `localhost` |
| `PORT` | HTTP port | `4000` |
| `POOL_SIZE` | Database connection pool size | `10` |
| `TELEMETRY_BACKEND` | Telemetry storage backend | `ets` |

### Application Configuration

```elixir
# config/config.exs
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
```

### Crucible Telemetry Integration

Crucible UI integrates seamlessly with `crucible_telemetry` for event streaming:

```elixir
# In your application that generates telemetry
config :crucible_telemetry,
  backend: :postgres,
  database_url: System.get_env("DATABASE_URL"),
  pubsub: CrucibleUI.PubSub
```

## Development

### Running Tests

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover

# Run specific test file
mix test test/crucible_ui_web/live/experiment_live_test.exs
```

### Code Quality

```bash
# Format code
mix format

# Run static analysis
mix dialyzer

# Run linter
mix credo --strict
```

### Asset Compilation

```bash
# Development (with watch)
cd assets && npm run watch

# Production build
cd assets && npm run deploy
mix phx.digest
```

### Database Management

```bash
# Create migration
mix ecto.gen.migration add_experiments_table

# Run migrations
mix ecto.migrate

# Reset database
mix ecto.reset
```

## Architecture

Crucible UI is built on a modern Phoenix LiveView architecture:

- **LiveView Components**: Real-time UI updates without JavaScript
- **PubSub Integration**: Event broadcasting for live updates
- **Ecto Schemas**: Persistent storage for experiments and results
- **Tailwind CSS**: Utility-first styling with custom components
- **Chart.js**: Interactive data visualizations

For detailed architecture documentation, see [docs/20251121/architecture.md](docs/20251121/architecture.md).

## API

Crucible UI exposes REST and WebSocket APIs for programmatic access:

- **REST API**: CRUD operations for experiments, models, and results
- **WebSocket**: Real-time event streaming and notifications
- **GraphQL** (planned): Flexible querying interface

For complete API documentation, see [docs/20251121/api_endpoints.md](docs/20251121/api_endpoints.md).

## Deployment

### Docker

```bash
# Build the image
docker build -t crucible_ui .

# Run the container
docker run -p 4000:4000 \
  -e DATABASE_URL=postgres://user:pass@host/db \
  -e SECRET_KEY_BASE=$(mix phx.gen.secret) \
  crucible_ui
```

### Fly.io

```bash
fly launch
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
fly deploy
```

For complete deployment instructions, see [docs/20251121/deployment.md](docs/20251121/deployment.md).

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Related Projects

- [crucible_framework](https://github.com/North-Shore-AI/crucible_framework) - Core reliability research framework
- [crucible_telemetry](https://github.com/North-Shore-AI/crucible_telemetry) - Research-grade instrumentation
- [crucible_ensemble](https://github.com/North-Shore-AI/crucible_ensemble) - Multi-model voting
- [crucible_bench](https://github.com/North-Shore-AI/crucible_bench) - Statistical testing

## License

Copyright 2024 North-Shore-AI

Licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
