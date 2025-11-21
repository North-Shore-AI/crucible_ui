// Chart.js hook for dynamic charts
const ChartHook = {
  mounted() {
    // Chart.js integration - requires Chart.js to be loaded
    if (window.Chart && this.el.dataset.chartType) {
      this.chart = new Chart(this.el, {
        type: this.el.dataset.chartType,
        data: JSON.parse(this.el.dataset.chartData || '{}'),
        options: JSON.parse(this.el.dataset.chartOptions || '{}')
      });
    }
  },
  updated() {
    if (this.chart && this.el.dataset.chartData) {
      const newData = JSON.parse(this.el.dataset.chartData);
      this.chart.data = newData;
      this.chart.update();
    }
  },
  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
};

// Copy to clipboard hook
const CopyHook = {
  mounted() {
    this.el.addEventListener("click", () => {
      const text = this.el.dataset.copyValue;
      if (text) {
        navigator.clipboard.writeText(text).then(() => {
          // Show feedback
          const originalText = this.el.innerText;
          this.el.innerText = "Copied!";
          setTimeout(() => {
            this.el.innerText = originalText;
          }, 2000);
        });
      }
    });
  }
};

// Auto-scroll hook for telemetry events
const AutoScrollHook = {
  mounted() {
    this.scrollToBottom();
  },
  updated() {
    if (this.el.dataset.autoScroll === "true") {
      this.scrollToBottom();
    }
  },
  scrollToBottom() {
    this.el.scrollTop = this.el.scrollHeight;
  }
};

// Timestamp formatting hook
const TimestampHook = {
  mounted() {
    this.formatTimestamp();
  },
  updated() {
    this.formatTimestamp();
  },
  formatTimestamp() {
    const timestamp = this.el.dataset.timestamp;
    if (timestamp) {
      const date = new Date(timestamp);
      this.el.innerText = date.toLocaleString();
    }
  }
};

// Tooltip hook
const TooltipHook = {
  mounted() {
    this.el.setAttribute("title", this.el.dataset.tooltip);
  }
};

// Highlight on update hook
const HighlightHook = {
  updated() {
    this.el.classList.add("bg-yellow-100");
    setTimeout(() => {
      this.el.classList.remove("bg-yellow-100");
    }, 1000);
  }
};

export default {
  Chart: ChartHook,
  Copy: CopyHook,
  AutoScroll: AutoScrollHook,
  Timestamp: TimestampHook,
  Tooltip: TooltipHook,
  Highlight: HighlightHook
};
