# Crucible UI API Endpoints

This document describes the REST and WebSocket APIs provided by Crucible UI.

## API Overview

### Base URL
```
https://your-domain.com/api/v1
```

### Authentication

All API requests require authentication via API key or session token.

**API Key Header**:
```
Authorization: Bearer <api_key>
```

**Session Cookie**:
```
Cookie: _crucible_ui_key=<session_token>
```

### Response Format

All responses are JSON with consistent structure:

**Success Response**:
```json
{
  "data": { ... },
  "meta": {
    "total": 100,
    "page": 1,
    "per_page": 25
  }
}
```

**Error Response**:
```json
{
  "error": {
    "code": "validation_error",
    "message": "Name is required",
    "details": {
      "name": ["can't be blank"]
    }
  }
}
```

### Common Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `page` | integer | Page number (default: 1) |
| `per_page` | integer | Items per page (default: 25, max: 100) |
| `sort` | string | Sort field (prefix with `-` for descending) |
| `filter[field]` | string | Filter by field value |

---

## Experiment Endpoints

### List Experiments

```
GET /api/v1/experiments
```

**Query Parameters**:
- `filter[status]`: Filter by status (pending, running, completed, failed, cancelled)
- `filter[name]`: Filter by name (partial match)
- `filter[created_after]`: ISO 8601 datetime
- `filter[created_before]`: ISO 8601 datetime
- `sort`: `name`, `created_at`, `updated_at`, `status` (default: `-created_at`)

**Response**:
```json
{
  "data": [
    {
      "id": "exp_abc123",
      "name": "Ensemble Comparison v1",
      "description": "Comparing voting strategies",
      "status": "running",
      "config": { ... },
      "started_at": "2024-01-15T10:30:00Z",
      "completed_at": null,
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    }
  ],
  "meta": {
    "total": 45,
    "page": 1,
    "per_page": 25
  }
}
```

### Get Experiment

```
GET /api/v1/experiments/:id
```

**Response**:
```json
{
  "data": {
    "id": "exp_abc123",
    "name": "Ensemble Comparison v1",
    "description": "Comparing voting strategies",
    "status": "running",
    "config": {
      "type": "ensemble",
      "models": ["gpt-4", "claude-3", "llama-2"],
      "voting_strategy": "weighted",
      "dataset": "mmlu"
    },
    "started_at": "2024-01-15T10:30:00Z",
    "completed_at": null,
    "runs": [
      {
        "id": "run_xyz789",
        "status": "running",
        "progress": 0.45
      }
    ],
    "results_summary": {
      "best_accuracy": 0.92,
      "total_runs": 3
    },
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

### Create Experiment

```
POST /api/v1/experiments
```

**Request Body**:
```json
{
  "experiment": {
    "name": "New Ensemble Test",
    "description": "Testing majority voting",
    "config": {
      "type": "ensemble",
      "models": ["gpt-4", "claude-3"],
      "voting_strategy": "majority",
      "dataset": "mmlu",
      "sample_size": 1000
    },
    "tags": ["ensemble", "comparison"]
  }
}
```

**Response**: `201 Created`
```json
{
  "data": {
    "id": "exp_new456",
    "name": "New Ensemble Test",
    "status": "pending",
    ...
  }
}
```

### Update Experiment

```
PATCH /api/v1/experiments/:id
```

**Request Body**:
```json
{
  "experiment": {
    "name": "Updated Name",
    "description": "Updated description"
  }
}
```

**Response**: `200 OK`

### Delete Experiment

```
DELETE /api/v1/experiments/:id
```

**Response**: `204 No Content`

### Experiment Actions

#### Start Experiment
```
POST /api/v1/experiments/:id/start
```

#### Pause Experiment
```
POST /api/v1/experiments/:id/pause
```

#### Resume Experiment
```
POST /api/v1/experiments/:id/resume
```

#### Cancel Experiment
```
POST /api/v1/experiments/:id/cancel
```

#### Clone Experiment
```
POST /api/v1/experiments/:id/clone
```

**Request Body**:
```json
{
  "name": "Cloned Experiment Name"
}
```

---

## Run Endpoints

### List Runs

```
GET /api/v1/runs
GET /api/v1/experiments/:experiment_id/runs
```

**Query Parameters**:
- `filter[status]`: pending, running, completed, failed
- `filter[experiment_id]`: Filter by experiment

### Get Run

```
GET /api/v1/runs/:id
```

**Response**:
```json
{
  "data": {
    "id": "run_xyz789",
    "experiment_id": "exp_abc123",
    "status": "running",
    "progress": 0.45,
    "hyperparameters": {
      "learning_rate": 0.001,
      "batch_size": 32,
      "epochs": 100
    },
    "metrics": {
      "current_epoch": 45,
      "train_loss": 0.234,
      "val_loss": 0.256,
      "val_accuracy": 0.89
    },
    "started_at": "2024-01-15T10:30:00Z",
    "checkpoints": [
      {
        "id": "ckpt_1",
        "epoch": 40,
        "val_accuracy": 0.88,
        "path": "/checkpoints/run_xyz789/epoch_40.pt"
      }
    ]
  }
}
```

### Get Run Logs

```
GET /api/v1/runs/:id/logs
```

**Query Parameters**:
- `level`: Filter by log level (debug, info, warning, error)
- `since`: ISO 8601 datetime
- `tail`: Number of most recent lines

**Response**:
```json
{
  "data": [
    {
      "timestamp": "2024-01-15T10:35:00Z",
      "level": "info",
      "message": "Epoch 45/100 - loss: 0.234"
    }
  ]
}
```

### List Checkpoints

```
GET /api/v1/runs/:id/checkpoints
```

### Download Checkpoint

```
GET /api/v1/runs/:id/checkpoints/:checkpoint_id/download
```

**Response**: Binary file download

---

## Telemetry Endpoints

### Ingest Events

```
POST /api/v1/telemetry/events
```

**Request Body**:
```json
{
  "events": [
    {
      "event_name": ["crucible", "model", "inference"],
      "measurements": {
        "duration_ms": 234,
        "tokens": 150
      },
      "metadata": {
        "experiment_id": "exp_abc123",
        "model": "gpt-4",
        "request_id": "req_12345"
      },
      "timestamp": "2024-01-15T10:35:00Z"
    }
  ]
}
```

**Response**: `202 Accepted`
```json
{
  "data": {
    "accepted": 1,
    "rejected": 0
  }
}
```

### Query Events

```
GET /api/v1/telemetry/events
```

**Query Parameters**:
- `filter[event_name]`: Event name (e.g., `crucible.model.inference`)
- `filter[experiment_id]`: Experiment ID
- `filter[after]`: ISO 8601 datetime
- `filter[before]`: ISO 8601 datetime
- `agg`: Aggregation function (count, avg, sum, min, max)
- `agg_field`: Field to aggregate
- `group_by`: Group aggregation by field

**Response**:
```json
{
  "data": [
    {
      "id": "evt_123",
      "event_name": ["crucible", "model", "inference"],
      "measurements": { ... },
      "metadata": { ... },
      "timestamp": "2024-01-15T10:35:00Z"
    }
  ]
}
```

### Aggregate Events

```
GET /api/v1/telemetry/aggregate
```

**Query Parameters**:
- `metric`: Measurement field to aggregate
- `agg`: count, avg, sum, min, max, p50, p95, p99
- `group_by`: Field to group by
- `interval`: Time interval (1m, 5m, 1h, 1d)
- Filters as above

**Response**:
```json
{
  "data": [
    {
      "timestamp": "2024-01-15T10:00:00Z",
      "value": 234.5
    },
    {
      "timestamp": "2024-01-15T11:00:00Z",
      "value": 198.3
    }
  ]
}
```

### Export Events

```
POST /api/v1/telemetry/export
```

**Request Body**:
```json
{
  "format": "csv",
  "filters": {
    "experiment_id": "exp_abc123",
    "after": "2024-01-15T00:00:00Z"
  },
  "fields": ["timestamp", "event_name", "measurements.duration_ms"]
}
```

**Response**: File download or async job ID

---

## Model Endpoints

### List Models

```
GET /api/v1/models
```

**Response**:
```json
{
  "data": [
    {
      "id": "model_gpt4",
      "name": "GPT-4",
      "provider": "openai",
      "type": "llm",
      "config": {
        "max_tokens": 4096,
        "temperature": 0.7
      },
      "status": "active"
    }
  ]
}
```

### Get Model

```
GET /api/v1/models/:id
```

### Create Model

```
POST /api/v1/models
```

**Request Body**:
```json
{
  "model": {
    "name": "Custom Model",
    "provider": "custom",
    "type": "llm",
    "config": {
      "endpoint": "https://api.example.com/v1/completions",
      "api_key_env": "CUSTOM_API_KEY"
    }
  }
}
```

### Update Model

```
PATCH /api/v1/models/:id
```

### Delete Model

```
DELETE /api/v1/models/:id
```

### Model Statistics

```
GET /api/v1/models/:id/statistics
```

**Query Parameters**:
- `period`: 1h, 24h, 7d, 30d

**Response**:
```json
{
  "data": {
    "total_requests": 10000,
    "success_rate": 0.995,
    "avg_latency_ms": 234,
    "p99_latency_ms": 890,
    "total_tokens": 1500000,
    "error_breakdown": {
      "timeout": 20,
      "rate_limit": 15,
      "server_error": 10
    }
  }
}
```

---

## Statistical Results Endpoints

### List Statistical Results

```
GET /api/v1/statistical-results
GET /api/v1/experiments/:experiment_id/statistical-results
```

### Get Statistical Result

```
GET /api/v1/statistical-results/:id
```

**Response**:
```json
{
  "data": {
    "id": "stat_123",
    "experiment_id": "exp_abc123",
    "test_type": "two_sample_t_test",
    "groups": ["model_a", "model_b"],
    "p_value": 0.0023,
    "effect_size": 0.85,
    "effect_size_type": "cohens_d",
    "confidence_interval": [0.45, 1.25],
    "sample_sizes": [100, 100],
    "means": [0.89, 0.82],
    "std_devs": [0.05, 0.08],
    "interpretation": {
      "significance": "significant",
      "effect_magnitude": "large",
      "practical_significance": "Model A significantly outperforms Model B"
    }
  }
}
```

### Run Statistical Test

```
POST /api/v1/statistical-results
```

**Request Body**:
```json
{
  "test": {
    "experiment_id": "exp_abc123",
    "test_type": "two_sample_t_test",
    "groups": ["model_a", "model_b"],
    "metric": "accuracy",
    "options": {
      "alpha": 0.05,
      "alternative": "two_sided"
    }
  }
}
```

---

## Export Endpoints

### Export Experiment

```
POST /api/v1/experiments/:id/export
```

**Request Body**:
```json
{
  "format": "json",
  "include": ["config", "results", "runs", "telemetry"]
}
```

### Export Comparison Report

```
POST /api/v1/export/comparison
```

**Request Body**:
```json
{
  "experiment_ids": ["exp_1", "exp_2"],
  "format": "latex",
  "template": "publication"
}
```

---

## WebSocket API

### Connection

```
wss://your-domain.com/socket/websocket
```

**Authentication**: Include token in connection params
```javascript
const socket = new Socket("/socket", {
  params: { token: "user_auth_token" }
});
```

### Channels

#### Experiment Channel

**Join**:
```javascript
const channel = socket.channel("experiment:exp_abc123", {});
channel.join();
```

**Events**:

| Event | Direction | Payload |
|-------|-----------|---------|
| `status_changed` | Server → Client | `{status: "completed", completed_at: ...}` |
| `progress_updated` | Server → Client | `{progress: 0.75, eta_seconds: 300}` |
| `run_completed` | Server → Client | `{run_id: "...", metrics: {...}}` |
| `error` | Server → Client | `{message: "...", code: "..."}` |

#### Telemetry Channel

**Join**:
```javascript
const channel = socket.channel("telemetry:exp_abc123", {});
// or for all events
const channel = socket.channel("telemetry:all", {});
```

**Events**:

| Event | Direction | Payload |
|-------|-----------|---------|
| `event` | Server → Client | Full event object |
| `subscribe` | Client → Server | `{event_types: ["model.inference"]}` |
| `unsubscribe` | Client → Server | `{event_types: ["model.inference"]}` |

#### Dashboard Channel

**Join**:
```javascript
const channel = socket.channel("dashboard:user_123", {});
```

**Events**:

| Event | Direction | Payload |
|-------|-----------|---------|
| `system_stats` | Server → Client | `{cpu: 45, memory: 60, gpu: 80}` |
| `experiment_summary` | Server → Client | `{active: 5, completed_today: 12}` |

---

## Rate Limiting

| Endpoint Type | Rate Limit |
|---------------|------------|
| Read endpoints | 1000 requests/minute |
| Write endpoints | 100 requests/minute |
| Telemetry ingest | 10000 events/minute |
| Export endpoints | 10 requests/minute |

**Headers**:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 950
X-RateLimit-Reset: 1705320000
```

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `unauthorized` | 401 | Invalid or missing authentication |
| `forbidden` | 403 | Insufficient permissions |
| `not_found` | 404 | Resource not found |
| `validation_error` | 422 | Invalid request parameters |
| `rate_limited` | 429 | Rate limit exceeded |
| `internal_error` | 500 | Server error |

---

## Versioning

The API uses URL versioning (`/api/v1/`). Breaking changes will result in a new version. Non-breaking additions may be made to existing versions.

## Pagination

All list endpoints support cursor-based pagination for large datasets:

```
GET /api/v1/experiments?cursor=eyJpZCI6MTIzfQ&per_page=25
```

**Response includes**:
```json
{
  "meta": {
    "next_cursor": "eyJpZCI6MTQ4fQ",
    "has_more": true
  }
}
```
