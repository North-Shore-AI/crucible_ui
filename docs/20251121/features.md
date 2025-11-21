# Crucible UI Feature Specifications

This document provides complete specifications for all features in Crucible UI.

## Dashboard Home

### System Overview Panel

**Purpose**: Provide at-a-glance system health and activity summary.

**Components**:
- **Active Experiments Counter**: Shows currently running experiments with status breakdown
- **Resource Utilization Gauges**: CPU, Memory, GPU usage across all active runs
- **Recent Activity Feed**: Last 10 events with timestamps
- **Quick Stats Cards**:
  - Total experiments (all time)
  - Completed today
  - Average success rate
  - Total training hours

**Real-time Updates**: Auto-refreshes every 5 seconds via PubSub.

### Navigation Sidebar

**Sections**:
- Dashboard (home)
- Experiments
  - All Experiments
  - Active
  - Completed
  - Failed
- Ensembles
- Statistical Tests
- Telemetry
- Model Comparison
- Settings

## Experiment Management

### Experiment Browser (List View)

**Features**:
- **Sortable Columns**: Name, Status, Created, Updated, Duration
- **Filtering**:
  - Status (pending, running, completed, failed, cancelled)
  - Date range
  - Tags
  - Search by name/description
- **Bulk Actions**: Delete, Export, Tag, Archive
- **Pagination**: 25/50/100 items per page

**Table Columns**:
| Column | Description | Sortable |
|--------|-------------|----------|
| Name | Experiment name with link to detail | Yes |
| Status | Visual status badge | Yes |
| Progress | Progress bar (if running) | No |
| Models | Number of models involved | Yes |
| Created | Creation timestamp | Yes |
| Duration | Running time or total time | Yes |
| Actions | Edit, Clone, Delete | No |

### Experiment Detail View

**Header Section**:
- Experiment name (editable inline)
- Status badge with state transitions
- Action buttons: Pause, Resume, Cancel, Clone, Export

**Tabs**:

#### Overview Tab
- Description and metadata
- Configuration summary
- Timeline visualization of experiment phases
- Key metrics summary

#### Runs Tab
- List of all training runs
- Run status, duration, final metrics
- Hyperparameter differences highlighted
- Actions: View logs, View checkpoints, Compare

#### Results Tab
- Final metrics table
- Best performing configuration
- Statistical test results summary
- Export options (CSV, JSON, LaTeX)

#### Telemetry Tab
- Real-time event stream
- Metric charts (loss, accuracy, etc.)
- Event filtering by type
- Export raw events

#### Configuration Tab
- Full configuration display (YAML/JSON)
- Edit configuration (for pending experiments)
- Version history

### Create Experiment Form

**Fields**:
- Name (required)
- Description
- Experiment type (ensemble, hedging, comparison, custom)
- Model selection (multi-select)
- Dataset selection
- Hyperparameters (dynamic form based on experiment type)
- Scheduling options
- Tags

**Validation**:
- Unique name within user's experiments
- Valid model and dataset selections
- Hyperparameter type checking

## Statistical Test Visualization

### Test Results List

**Supported Tests**:
- t-tests (one-sample, two-sample, paired)
- ANOVA (one-way, two-way)
- Mann-Whitney U
- Wilcoxon signed-rank
- Kruskal-Wallis
- Chi-squared
- Fisher's exact

**Display Fields**:
- Test name and type
- Compared groups
- P-value (with significance stars)
- Effect size and type
- Confidence interval
- Sample sizes

### Individual Test Detail View

**Visualizations**:

#### Distribution Plots
- Histogram/density plot for each group
- Box plots side-by-side
- Violin plots for distribution shape

#### Effect Size Display
- Magnitude indicator (small/medium/large)
- Visual comparison bar
- Interpretation guidelines

#### P-value Context
- P-value on logarithmic scale
- Common thresholds marked (0.05, 0.01, 0.001)
- Multiple comparison correction status

#### Assumptions Panel
- Normality test results
- Homogeneity of variance
- Independence assessment
- Warnings for violated assumptions

### Statistical Summary Dashboard

**Features**:
- All tests from an experiment in one view
- Significance matrix (pairwise comparisons)
- Forest plot of effect sizes
- Power analysis results
- Publication-ready table export

## Ensemble Performance Dashboards

### Ensemble Overview

**Summary Cards**:
- Total ensembles configured
- Active ensembles
- Average accuracy improvement over single models
- Best performing ensemble

### Ensemble Detail View

**Configuration Panel**:
- Voting strategy (majority, weighted, best_confidence, unanimous)
- Execution mode (parallel, sequential, hedged, cascade)
- Member models list
- Threshold settings

**Performance Metrics**:

#### Accuracy Chart
- Time series of ensemble accuracy
- Individual model accuracies overlay
- Baseline comparison line

#### Voting Analysis
- Agreement rate between models
- Disagreement heatmap
- Cases where voting changed outcome

#### Model Contribution
- Pie chart of weighted contributions
- Correlation matrix between model predictions
- Individual model reliability scores

#### Cost-Accuracy Trade-off
- Scatter plot: cost vs accuracy
- Pareto frontier highlighting
- Optimal configuration recommendation

### Model Voting Visualization

**Real-time Voting Display**:
- Input query display
- Each model's prediction with confidence
- Aggregation visualization
- Final ensemble decision
- Confidence score

## Hedging Latency Charts

### Hedging Strategy Overview

**Strategy Comparison**:
- Fixed delay
- Percentile-based
- Adaptive
- Workload-aware

**Key Metrics**:
- P50, P95, P99 latency
- Success rate
- Cost overhead
- Requests hedged percentage

### Latency Distribution Charts

**Visualizations**:

#### CDF Plot
- Cumulative distribution function
- Strategy comparison overlay
- Target latency markers

#### Latency Histogram
- Response time distribution
- Primary vs hedge request breakdown
- Tail latency highlighting

#### Time Series
- Latency over time
- Moving average trend
- Anomaly detection markers

### Cost Analysis

**Displays**:
- Additional requests due to hedging
- Cost per successful request
- Cost vs latency improvement scatter
- Break-even analysis

## Model Performance Comparisons

### Comparison View

**Selection Interface**:
- Model picker (up to 6 models)
- Metric selector
- Date range
- Dataset filter

**Comparison Charts**:

#### Radar Chart
- Multi-metric comparison
- Normalized scores
- Customizable dimensions

#### Bar Chart Groups
- Side-by-side metric comparison
- Error bars for variance
- Statistical significance markers

#### Performance Table
- All metrics in tabular form
- Best value highlighting
- Percentage differences

### Statistical Comparison

**Features**:
- Automatic test selection based on data
- Pairwise comparisons
- Multiple comparison correction
- Effect sizes with confidence intervals

### Trend Comparison

**Time Series Analysis**:
- Model performance over time
- Training progression comparison
- Convergence analysis
- Stability assessment

## Training Run Management

### Run List View

**Columns**:
- Run ID
- Experiment
- Status (with progress)
- Start time
- Duration
- Key metrics
- Actions

**Filters**:
- Status
- Experiment
- Date range
- Performance threshold

### Run Detail View

**Sections**:

#### Status Panel
- Current status with history
- Progress bar (if running)
- Estimated completion time
- Resource usage

#### Hyperparameters
- Full hyperparameter table
- Comparison with default/best
- Change history

#### Metrics
- Training curves (loss, accuracy, etc.)
- Validation metrics
- Custom metric support
- Best checkpoint highlighting

#### Logs
- Real-time log streaming
- Log level filtering
- Search functionality
- Download option

#### Checkpoints
- Checkpoint list with timestamps
- Metrics at checkpoint
- Actions: Load, Delete, Export

### Run Actions

**Available Actions**:
- **Pause**: Suspend training (saves state)
- **Resume**: Continue from last checkpoint
- **Cancel**: Stop and mark as cancelled
- **Clone**: Create new run with same config
- **Export**: Download model/checkpoint

### Multi-Run Comparison

**Features**:
- Select runs to compare
- Overlay training curves
- Hyperparameter diff table
- Metric comparison table
- Statistical tests between runs

## Telemetry Event Streaming

### Event Feed

**Display Options**:
- Live stream (newest first)
- Paused view with manual refresh
- Filtered view

**Event Card**:
- Event type icon
- Timestamp
- Event name
- Key measurements
- Expandable details

### Event Filtering

**Filter Options**:
- Event type (experiment, ensemble, hedging, model, custom)
- Experiment ID
- Time range
- Measurement thresholds
- Metadata fields

### Event Aggregation

**Aggregation Views**:
- Event count by type (pie chart)
- Events over time (histogram)
- Average measurements by type
- Custom aggregations

### Export Options

**Formats**:
- CSV (flat structure)
- JSON Lines (streaming)
- Parquet (columnar)

**Options**:
- Select fields
- Apply filters
- Date range
- Compression

## Settings and Configuration

### User Preferences

**Options**:
- Theme (light/dark/system)
- Default page size
- Refresh interval
- Notification preferences
- Time zone

### Dashboard Configuration

**Customization**:
- Widget arrangement
- Default charts
- Quick action buttons
- Keyboard shortcuts

### API Keys

**Management**:
- Generate new keys
- List active keys
- Revoke keys
- Set permissions

### Integrations

**Supported Integrations**:
- Crucible Telemetry (backend URL)
- Slack (notifications)
- Email (alerts)
- Webhooks (custom)

## Accessibility Features

### Keyboard Navigation
- Full keyboard support
- Skip links
- Focus indicators
- Shortcut hints

### Screen Reader Support
- ARIA labels
- Live regions for updates
- Semantic HTML
- Alt text for charts

### Visual Accommodations
- High contrast mode
- Adjustable font size
- Color blind friendly palettes
- Reduced motion option
