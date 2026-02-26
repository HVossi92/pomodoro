// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import { getSessionStatsData, saveSessionStatsData } from "./session_stats_storage.js"

// Dark mode setup
const setupDarkMode = () => {
  // Check for saved theme preference or OS preference
  const isDarkMode = localStorage.getItem('darkMode') === 'true' ||
    (!localStorage.getItem('darkMode') && window.matchMedia('(prefers-color-scheme: dark)').matches);

  // Apply the theme
  if (isDarkMode) {
    document.documentElement.classList.add('dark');
  } else {
    document.documentElement.classList.remove('dark');
  }

  // Set up toggle functionality
  document.addEventListener('DOMContentLoaded', () => {
    const darkModeToggle = document.getElementById('dark-mode-toggle');
    if (darkModeToggle) {
      darkModeToggle.addEventListener('click', () => {
        const isDark = document.documentElement.classList.toggle('dark');
        localStorage.setItem('darkMode', isDark);
      });
    }
  });

  // Listen for OS theme changes
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
    if (localStorage.getItem('darkMode') === null) {
      if (e.matches) {
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
      }
    }
  });
};

// Initialize dark mode
setupDarkMode();

// Define the storage key globally
window.POMODORO_USER_ID_KEY = "pomodoro_user_id";

// Define Hooks for LiveView
const Hooks = {}

// Hook for buttons/links that require confirmation before firing phx-click.
// Use with phx-hook="Confirm" data-confirm="Your message" data-phx-event="event_name" phx-value-*="..."
Hooks.Confirm = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      const msg = this.el.getAttribute("data-confirm");
      if (msg && !confirm(msg)) {
        e.preventDefault();
        e.stopPropagation();
        return;
      }
      const event = this.el.getAttribute("data-phx-event");
      if (!event) return;
      e.preventDefault();
      e.stopPropagation();
      const params = {};
      for (const attr of this.el.attributes) {
        if (attr.name.startsWith("phx-value-") && attr.name !== "phx-value-static") {
          const key = attr.name.replace("phx-value-", "").replace(/-/g, "_");
          const keys = key.split("_");
          if (keys.length === 1) {
            params[key] = attr.value;
          } else {
            params[keys[0]] = attr.value;
          }
        }
      }
      this.pushEvent(event, params);
    });
  }
};

// Hook to update page title based on timer state
Hooks.TimerTitleHook = {
  mounted() {
    this.handleEvent("timer-update", ({ seconds_left }) => {
      document.title = `Pomo Focus - ${formatTime(seconds_left)}`;
    });
  }
}

// Session stats: streak, heatmap; DB-backed, optional localStorage cache
Hooks.SessionStatsHook = {
  mounted() {
    this.renderPanel({ sessions: [], streak: 0, heatmap: {} });
    const data = getSessionStatsData();
    this.pushEvent("session_stats_update", { sessions: data.sessions || [] });

    this.handleEvent("session-stats-init", ({ sessions, streak, heatmap }) => {
      saveSessionStatsData({ sessions: sessions || [] });
      this.renderPanel({ sessions: sessions || [], streak: streak ?? 0, heatmap: heatmap || {} });
    });

    this.handleEvent("pomodoro-complete", () => {
      // Server increments DB and pushes session-stats-update; no local action needed
    });

    this.handleEvent("session-stats-update", ({ sessions, streak, heatmap }) => {
      saveSessionStatsData({ sessions: sessions || [] });
      this.renderPanel({ sessions: sessions || [], streak: streak ?? 0, heatmap: heatmap || {} });
    });
  },

  renderPanel(data) {
    const streak = data.streak != null ? data.streak : 0;
    const heatmap = data.heatmap || {};
    const sessions = data.sessions || [];
    const el = this.el;

    const countByDate = {};
    for (const s of sessions) {
      countByDate[s.date] = s.count ?? 0;
    }

    const streakColorClass = streak === 0
      ? "text-red-600 dark:text-red-400"
      : streak <= 2
        ? "text-yellow-600 dark:text-yellow-400"
        : "text-green-600 dark:text-green-400";
    const heatmapHtml = this.renderHeatmap(heatmap, countByDate);
    el.innerHTML = `
      <div class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow">
        <h3 class="text-lg font-semibold text-gray-700 dark:text-gray-300 mb-2">Session stats</h3>
        <p class="text-2xl font-bold ${streakColorClass} mb-4">
          ${streak} day streak
        </p>
        <div class="heatmap-wrapper w-full max-w-full overflow-hidden relative">
          ${heatmapHtml}
        </div>
        <div id="heatmap-tooltip" class="heatmap-tooltip hidden fixed z-[100] px-2 py-1 text-xs font-medium text-gray-800 dark:text-gray-200 bg-gray-100 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded shadow-lg pointer-events-none whitespace-nowrap" role="tooltip"></div>
        <a href="/settings" class="mt-4 inline-block text-sm font-medium text-gray-600 dark:text-gray-400 hover:underline" aria-label="Settings">Settings</a>
      </div>
    `;
    this.attachHeatmapTooltip(el);
  },

  attachHeatmapTooltip(panelEl) {
    const wrapper = panelEl.querySelector(".heatmap-wrapper");
    const tooltipEl = panelEl.querySelector("#heatmap-tooltip");
    if (!wrapper || !tooltipEl) return;

    const show = (text, clientX, clientY) => {
      tooltipEl.textContent = text;
      tooltipEl.classList.remove("hidden");
      const offset = 12;
      tooltipEl.style.left = `${clientX + offset}px`;
      tooltipEl.style.top = `${clientY + offset}px`;
    };
    const hide = () => {
      tooltipEl.classList.add("hidden");
    };

    wrapper.addEventListener("mousemove", (e) => {
      const rect = e.target.closest("rect[data-date]");
      if (rect) {
        const date = rect.getAttribute("data-date");
        const count = parseInt(rect.getAttribute("data-count") || "0", 10);
        const text = count === 0
          ? `No Pomodoros on ${date} :'(`
          : `${count} pomodoro(s) on ${date}`;
        show(text, e.clientX, e.clientY);
      } else {
        hide();
      }
    });
    wrapper.addEventListener("mouseleave", hide);
  },

  dateStringAtOffset(offset) {
    const d = new Date();
    d.setDate(d.getDate() - (363 - offset));
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, "0");
    const day = String(d.getDate()).padStart(2, "0");
    return `${y}-${m}-${day}`;
  },

  heatmapBucketColor(bucket) {
    const colors = [
      "#e5e7eb",
      "#bbf7d0",
      "#4ade80",
      "#22c55e",
      "#166534"
    ];
    const darkColors = [
      "#374151",
      "#14532d",
      "#166534",
      "#22c55e",
      "#4ade80"
    ];
    const isDark = document.documentElement.classList.contains("dark");
    const palette = isDark ? darkColors : colors;
    return palette[bucket] || palette[0];
  },

  renderHeatmap(heatmap, countByDate) {
    const size = 18;
    const gap = 3;
    const monthRowHeight = 28;
    const cols = 52;
    const gridWidth = cols * (size + gap) - gap;
    const gridHeight = 7 * (size + gap) - gap;
    const totalWidth = gridWidth;
    const totalHeight = monthRowHeight + gridHeight;

    const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const minLabelSpacing = 36;
    const monthLabels = [];
    let lastMonthKey = null;
    let lastLabelX = -Infinity;
    for (let i = 0; i < 364; i++) {
      const dateStr = this.dateStringAtOffset(i);
      const monthKey = dateStr.slice(0, 7);
      if (monthKey !== lastMonthKey) {
        const col = Math.floor(i / 7);
        const x = col * (size + gap);
        if (x - lastLabelX >= minLabelSpacing) {
          const [, monthPart] = dateStr.split("-");
          const monthIndex = parseInt(monthPart, 10) - 1;
          monthLabels.push({ label: monthNames[monthIndex] || monthPart, x });
          lastLabelX = x;
        }
        lastMonthKey = monthKey;
      }
    }

    const cells = [];
    for (let i = 0; i < 364; i++) {
      const dateStr = this.dateStringAtOffset(i);
      const bucket = heatmap[dateStr] != null ? heatmap[dateStr] : 0;
      const count = (countByDate && countByDate[dateStr]) ?? 0;
      const col = Math.floor(i / 7);
      const row = i % 7;
      const x = col * (size + gap);
      const y = monthRowHeight + row * (size + gap);
      const fill = this.heatmapBucketColor(bucket);
      const title = count === 0
        ? `No Pomodoros on ${dateStr} :'(`
        : `${count} pomodoro(s) on ${dateStr}`;
      cells.push(
        `<rect x="${x}" y="${y}" width="${size}" height="${size}" fill="${fill}" rx="2" data-date="${dateStr}" data-count="${count}" data-title="${title.replace(/"/g, "&quot;")}"><title>${title}</title></rect>`
      );
    }

    const monthTexts = monthLabels.map(
      ({ label, x }) => `<text x="${x}" y="18" text-anchor="start" class="fill-gray-500 dark:fill-gray-400" style="font-size:14px;font-family:system-ui,sans-serif">${label}</text>`
    ).join("");

    return `<svg width="100%" height="auto" viewBox="0 0 ${totalWidth} ${totalHeight}" preserveAspectRatio="xMidYMid meet" class="heatmap-grid block cursor-pointer" role="img" aria-label="Session heatmap">${monthTexts}${cells.join("")}</svg>`;
  }
}

// Format time helper function
function formatTime(seconds) {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${String(minutes).padStart(2, '0')}:${String(remainingSeconds).padStart(2, '0')}`;
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

