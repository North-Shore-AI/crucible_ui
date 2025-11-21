# Crucible UI Deployment Guide

This document provides comprehensive instructions for deploying Crucible UI to production environments.

## Prerequisites

- Elixir 1.14+ and Erlang/OTP 25+
- PostgreSQL 14+
- Node.js 18+ (for asset compilation)
- Docker (optional, for containerized deployment)

## Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgres://user:pass@host:5432/crucible_ui` |
| `SECRET_KEY_BASE` | Phoenix secret key (64+ chars) | Generate with `mix phx.gen.secret` |
| `PHX_HOST` | Production hostname | `crucible.example.com` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | HTTP port | `4000` |
| `POOL_SIZE` | Database connection pool | `10` |
| `PHX_SERVER` | Start server automatically | `true` |
| `MIX_ENV` | Environment | `prod` |
| `TELEMETRY_BACKEND` | Storage backend (ets/postgres) | `postgres` |
| `LOG_LEVEL` | Logging level | `info` |
| `SSL_KEY_PATH` | Path to SSL key file | - |
| `SSL_CERT_PATH` | Path to SSL certificate | - |

### Generate Secret Key

```bash
mix phx.gen.secret
# Output: Kcaw...Zj8= (64+ character string)
```

---

## Docker Deployment

### Dockerfile

```dockerfile
# Build stage
FROM hexpm/elixir:1.15.7-erlang-26.1.2-alpine-3.18.4 as build

# Install build dependencies
RUN apk add --no-cache build-base git npm

WORKDIR /app

# Install Elixir dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only prod
RUN mix deps.compile

# Install Node dependencies and build assets
COPY assets assets
RUN cd assets && npm ci && npm run deploy
RUN mix assets.deploy

# Compile application
COPY lib lib
COPY priv priv
RUN mix compile

# Build release
RUN mix release

# Runtime stage
FROM alpine:3.18.4 as app

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

# Copy release from build stage
COPY --from=build /app/_build/prod/rel/crucible_ui ./

# Set environment
ENV HOME=/app
ENV MIX_ENV=prod
ENV PHX_SERVER=true

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4000/health || exit 1

# Start application
CMD ["bin/crucible_ui", "start"]
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "4000:4000"
    environment:
      - DATABASE_URL=postgres://crucible:crucible@db:5432/crucible_ui_prod
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - PHX_HOST=${PHX_HOST:-localhost}
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=crucible
      - POSTGRES_PASSWORD=crucible
      - POSTGRES_DB=crucible_ui_prod
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U crucible"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  postgres_data:
```

### Build and Run

```bash
# Build the image
docker build -t crucible_ui:latest .

# Run with docker-compose
SECRET_KEY_BASE=$(mix phx.gen.secret) PHX_HOST=crucible.example.com docker-compose up -d

# Run database migrations
docker-compose exec app bin/crucible_ui eval "CrucibleUI.Release.migrate"
```

---

## Database Setup

### PostgreSQL Configuration

**Recommended settings for production** (`postgresql.conf`):

```ini
# Connection settings
max_connections = 100
shared_buffers = 256MB

# Performance
effective_cache_size = 768MB
work_mem = 4MB
maintenance_work_mem = 64MB

# Write-ahead log
wal_buffers = 8MB
checkpoint_completion_target = 0.9

# Query planning
random_page_cost = 1.1
effective_io_concurrency = 200
```

### Create Database and User

```sql
-- Connect as superuser
CREATE USER crucible WITH PASSWORD 'secure_password';
CREATE DATABASE crucible_ui_prod OWNER crucible;
GRANT ALL PRIVILEGES ON DATABASE crucible_ui_prod TO crucible;

-- Enable extensions
\c crucible_ui_prod
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
```

### Run Migrations

```bash
# Using release
bin/crucible_ui eval "CrucibleUI.Release.migrate"

# Using mix (development)
MIX_ENV=prod mix ecto.migrate
```

### Database Backups

```bash
# Backup
pg_dump -h localhost -U crucible -d crucible_ui_prod -F c -f backup.dump

# Restore
pg_restore -h localhost -U crucible -d crucible_ui_prod -c backup.dump
```

---

## Reverse Proxy Configuration

### Nginx

```nginx
upstream crucible_ui {
    server 127.0.0.1:4000;
}

server {
    listen 80;
    server_name crucible.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name crucible.example.com;

    ssl_certificate /etc/letsencrypt/live/crucible.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/crucible.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;

    # WebSocket support
    location /socket {
        proxy_pass http://crucible_ui;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }

    location / {
        proxy_pass http://crucible_ui;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static assets caching
    location /assets {
        proxy_pass http://crucible_ui;
        proxy_cache_valid 200 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### Caddy

```caddyfile
crucible.example.com {
    reverse_proxy localhost:4000

    @websocket {
        header Connection *Upgrade*
        header Upgrade websocket
    }
    reverse_proxy @websocket localhost:4000
}
```

---

## Platform-Specific Deployments

### Fly.io

**fly.toml**:
```toml
app = "crucible-ui"
primary_region = "ord"

[build]
  dockerfile = "Dockerfile"

[env]
  PHX_HOST = "crucible-ui.fly.dev"
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1

  [http_service.concurrency]
    type = "connections"
    hard_limit = 1000
    soft_limit = 1000

[[services]]
  protocol = "tcp"
  internal_port = 8080

  [[services.ports]]
    port = 80
    handlers = ["http"]

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]

  [[services.tcp_checks]]
    interval = "15s"
    timeout = "2s"
    grace_period = "1s"
```

**Deploy Commands**:
```bash
# Launch (first time)
fly launch

# Set secrets
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
fly secrets set DATABASE_URL=postgres://...

# Create Postgres
fly postgres create --name crucible-ui-db
fly postgres attach crucible-ui-db

# Deploy
fly deploy

# Run migrations
fly ssh console -C "/app/bin/crucible_ui eval 'CrucibleUI.Release.migrate'"
```

### AWS ECS

**Task Definition** (task-definition.json):
```json
{
  "family": "crucible-ui",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "crucible-ui",
      "image": "ACCOUNT.dkr.ecr.REGION.amazonaws.com/crucible-ui:latest",
      "portMappings": [
        {
          "containerPort": 4000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "PHX_HOST", "value": "crucible.example.com"},
        {"name": "PORT", "value": "4000"}
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:REGION:ACCOUNT:secret:crucible-ui/database-url"
        },
        {
          "name": "SECRET_KEY_BASE",
          "valueFrom": "arn:aws:secretsmanager:REGION:ACCOUNT:secret:crucible-ui/secret-key-base"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/crucible-ui",
          "awslogs-region": "REGION",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:4000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3
      }
    }
  ]
}
```

### Kubernetes

**Deployment** (k8s/deployment.yaml):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: crucible-ui
spec:
  replicas: 3
  selector:
    matchLabels:
      app: crucible-ui
  template:
    metadata:
      labels:
        app: crucible-ui
    spec:
      containers:
        - name: crucible-ui
          image: crucible-ui:latest
          ports:
            - containerPort: 4000
          env:
            - name: PHX_HOST
              value: crucible.example.com
            - name: PORT
              value: "4000"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: crucible-ui-secrets
                  key: database-url
            - name: SECRET_KEY_BASE
              valueFrom:
                secretKeyRef:
                  name: crucible-ui-secrets
                  key: secret-key-base
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: 4000
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 4000
            initialDelaySeconds: 5
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: crucible-ui
spec:
  selector:
    app: crucible-ui
  ports:
    - port: 80
      targetPort: 4000
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: crucible-ui
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - crucible.example.com
      secretName: crucible-ui-tls
  rules:
    - host: crucible.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: crucible-ui
                port:
                  number: 80
```

---

## Monitoring

### Health Check Endpoint

Add to your router:

```elixir
# lib/crucible_ui_web/router.ex
get "/health", HealthController, :index
```

```elixir
# lib/crucible_ui_web/controllers/health_controller.ex
defmodule CrucibleUIWeb.HealthController do
  use CrucibleUIWeb, :controller

  def index(conn, _params) do
    case check_health() do
      :ok ->
        json(conn, %{status: "ok", timestamp: DateTime.utc_now()})

      {:error, reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{status: "error", reason: reason})
    end
  end

  defp check_health do
    # Check database connection
    case Ecto.Adapters.SQL.query(CrucibleUI.Repo, "SELECT 1") do
      {:ok, _} -> :ok
      {:error, _} -> {:error, "database_unavailable"}
    end
  end
end
```

### Prometheus Metrics

Using PromEx:

```elixir
# config/config.exs
config :crucible_ui, CrucibleUI.PromEx,
  disabled: false,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  grafana: :disabled,
  metrics_server: :disabled
```

Access metrics at `/metrics`.

### Logging

Configure structured logging:

```elixir
# config/prod.exs
config :logger, :console,
  format: {LogfmtEx, :format},
  metadata: [:request_id, :user_id, :experiment_id]

config :logger,
  level: :info
```

### Error Tracking

Using Sentry:

```elixir
# config/prod.exs
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()]
```

---

## Performance Tuning

### BEAM VM Settings

```bash
# rel/env.sh.eex
export ERL_AFLAGS="-proto_dist inet6_tcp"
export ELIXIR_ERL_OPTIONS="+sbwt very_short +sbwtdcpu very_short +sbwtdio very_short"

# Adjust schedulers for container CPU limits
export ELIXIR_ERL_OPTIONS="$ELIXIR_ERL_OPTIONS +S 2:2"
```

### Database Connection Pool

```elixir
# config/runtime.exs
config :crucible_ui, CrucibleUI.Repo,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  queue_target: 5000,
  queue_interval: 1000
```

### Phoenix Endpoint

```elixir
# config/prod.exs
config :crucible_ui, CrucibleUIWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  check_origin: ["https://crucible.example.com"]
```

---

## Security Checklist

- [ ] Use HTTPS in production
- [ ] Set strong `SECRET_KEY_BASE`
- [ ] Configure `check_origin` for WebSockets
- [ ] Use environment variables for secrets
- [ ] Enable database SSL
- [ ] Set up firewall rules
- [ ] Configure rate limiting
- [ ] Enable audit logging
- [ ] Regular security updates
- [ ] Backup encryption

---

## Troubleshooting

### Common Issues

**WebSocket Connection Fails**:
- Check reverse proxy WebSocket configuration
- Verify `check_origin` settings
- Check for connection timeouts

**Database Connection Errors**:
- Verify `DATABASE_URL` format
- Check network connectivity
- Increase pool size if needed

**Asset Loading Issues**:
- Run `mix assets.deploy`
- Check `cache_static_manifest` path
- Verify Nginx/CDN caching headers

### Logs

```bash
# Docker
docker logs crucible_ui

# Fly.io
fly logs

# Kubernetes
kubectl logs -l app=crucible-ui
```

### Remote Console

```bash
# Connect to running node
bin/crucible_ui remote

# Fly.io
fly ssh console -C "/app/bin/crucible_ui remote"
```
