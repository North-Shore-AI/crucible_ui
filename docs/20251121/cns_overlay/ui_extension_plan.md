# CNS Overlay Extension Plan

## Objective

Position Crucible UI as the foundational Phoenix dashboard and describe how CNS-specific experiences should layer on top without duplicating backend logic or Tinkex integrations.

## Layering Model

1. **Foundation (Crucible UI Core)**
   - Experiment CRUD, run lifecycle controls (start/pause/cancel) via Crucible Framework APIs.
   - Telemetry timeline, resource metrics, statistical dashboards, ensemble/hedging tooling.
   - Shared LiveComponents (charts, run tables, KPI cards) exported for reuse.

2. **Extension (CNS Feature Pack)**
   - Mounts inside Crucible UI (e.g., `/cns/*`) or ships as a Phoenix component library consumed by CNS UI.
   - Adds SNO explorers, chirality/β₁ visualizations, citation health panels.
   - Consumes the same experiment/run context from Crucible UI, filtering by `domain: :cns` metadata.

3. **Standalone (CNS UI)**
   - Lightweight Phoenix app that imports Crucible UI components + contexts.
   - Provides a domain-focused navigation shell while delegating training orchestration to Crucible services.

## Required Workstreams

### 1. Component Extraction

- [x] Move reusable dashboard primitives into `CnsUiWeb.Components.Shared` (e.g., `stat_card/1`, `status_badge/1`) **in cns_ui repo**.
- [x] Provide `CnsUiWeb.Components.RunStream` LiveComponent that handles PubSub wiring given a `run_id` (Phoenix topic `run:{id}`) **in cns_ui repo**.
- [x] Document props/assigns so CNS UI can embed components without copying templates (see below).

### 2. API Client Layer

- [x] Introduce `CnsUi.Client` module encapsulating calls to the Crucible Framework API (`list_runs/1`, `create_run/1`, `stream_run/2`), defaulting to stubbed data when no base URL is configured **in cns_ui repo**.
- [x] Support configurable base URL + API token to accommodate local vs. production deployments (`:cns_ui, :client` config + `CRUCIBLE_API_BASE_URL` / `CRUCIBLE_API_TOKEN` env).
- [x] Emit instrumentation events (`:cns_ui, :api, event`) including `duration_ms` and result flag.

### 3. CNS-specific Views

- [x] Build overlay dashboard route shell composed of:
  - Run selector filtered to CNS experiments.
  - Overlay health and route panels (chirality gauges, citation heatmaps, metric timelines still TODO).
  - Implemented as `/overlay` LiveView **in cns_ui repo**.
- [ ] Add training wizard step that POSTs to `POST /v1/jobs` (Crucible Framework) and navigates to a shared run detail view.

### 4. Packaging Strategy

- [ ] Publish component library as hex package (e.g., `crucible_ui_components`) for import into CNS UI.
- [ ] Provide generator mix task (`mix crucible.gen.cns_overlay`) that scaffolds the CNS panel inside an existing Phoenix app.

## Acceptance Criteria

- CNS UI (or any downstream app) can embed Crucible UI components to monitor runs without duplicating markup.
- Starting a CNS-targeted training job calls the Crucible Framework API through the shared client layer.
- Crucible UI remains Tinkex-free; only the framework maintains the SDK dependency.

## Implemented modules (MVP, now housed in `../cns_ui`)

- `CnsUiWeb.Components.Shared`
  - `stat_card/1` (`title`, `value`, optional `hint`, `icon`, `tone`)
  - `status_badge/1` (`status`, optional `label`)
- `CnsUiWeb.Components.RunStream`
  - Assigns: `run_id` (required)
  - Behavior: subscribes to `run:{run_id}`, renders status/progress with Phoenix PubSub updates.
- `CnsUi.Client`
  - `list_runs/1`, `create_run/2`, `stream_run/2`
  - Config: `:cns_ui, :client` with `:base_url`, `:api_token`, optional headers; env overrides `CRUCIBLE_API_BASE_URL` and `CRUCIBLE_API_TOKEN`.
  - Telemetry: `[:cns_ui, :api, event]` with `duration_ms`, `result` (`:ok`|`:error`).
- `CnsUi.CNS` adapters
  - Default stub (`CnsUi.CNS.StubAdapter`) and HTTP adapter for `/overlays` + `/routes`.
- Route: `/overlay` in CNS UI (overlay health + run stream UI) using the above components.
