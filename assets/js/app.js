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

// Hook to handle user ID persistence across tabs and refreshes
Hooks.UserIdHook = {
  mounted() {
    // Handle server sending a user ID to store
    this.handleEvent("init-user-id", ({ user_id, local_storage_key }) => {
      // Store the key globally
      window.POMODORO_USER_ID_KEY = local_storage_key;
      // Check if we already have a user ID in localStorage
      const storedUserId = localStorage.getItem(local_storage_key);

      if (storedUserId && storedUserId !== user_id) {
        // If the stored ID is different from the one provided by the server,
        // push the stored one to the server
        this.pushEvent("user_id_from_storage", { user_id: storedUserId });
      } else if (!storedUserId) {
        // If no ID in localStorage, store the one from the server
        localStorage.setItem(local_storage_key, user_id);
      }
    });
  }
}

// Hook to handle timer title updates in background tabs
Hooks.TimerTitleHook = {
  mounted() {
    this.timerRef = null;
    this.lastSecondsLeft = parseInt(this.el.dataset.secondsLeft);
    this.isRunning = this.el.dataset.running === "true";
    this.prefix = "Pomo Focus - ";

    // Initialize timer if it's running
    this.updateTimerTitle(this.isRunning, this.lastSecondsLeft);

    // Listen for timer updates
    this.handleEvent("timer-update", ({ running, seconds_left }) => {
      this.isRunning = running;
      this.lastSecondsLeft = seconds_left;
      this.updateTimerTitle(running, seconds_left);
    });
  },

  updateTimerTitle(running, secondsLeft) {
    // Clear any existing timer
    if (this.timerRef) {
      clearInterval(this.timerRef);
      this.timerRef = null;
    }

    // If timer is running, create a JavaScript timer to update the title
    if (running) {
      let currentSeconds = secondsLeft;

      // Immediately update title
      document.title = this.prefix + this.formatTime(currentSeconds);

      // Set up interval to keep updating title even when tab is inactive
      this.timerRef = setInterval(() => {
        if (currentSeconds > 0) {
          currentSeconds--;
          document.title = this.prefix + this.formatTime(currentSeconds);
        } else {
          // Stop the timer when it reaches zero
          clearInterval(this.timerRef);
          this.timerRef = null;
        }
      }, 1000);
    } else {
      // Just set the title once if not running
      document.title = this.prefix + this.formatTime(secondsLeft);
    }
  },

  formatTime(seconds) {
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  },

  updated() {
    // When the component updates, get new values
    const newSecondsLeft = parseInt(this.el.dataset.secondsLeft);
    const newIsRunning = this.el.dataset.running === "true";

    // Only update if something changed
    if (newSecondsLeft !== this.lastSecondsLeft || newIsRunning !== this.isRunning) {
      this.lastSecondsLeft = newSecondsLeft;
      this.isRunning = newIsRunning;
      this.updateTimerTitle(newIsRunning, newSecondsLeft);
    }
  },

  destroyed() {
    // Clean up timer when component is removed
    if (this.timerRef) {
      clearInterval(this.timerRef);
      this.timerRef = null;
    }
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
  // Add these configs for better reconnection handling
  reconnectAfterMs: (tries) => {
    // Try to reconnect quickly first, then with increasing backoff
    return [100, 250, 500, 1000, 2000, 5000][tries - 1] || 10000;
  },
  // Keep the websocket connection alive with periodic heartbeats
  heartbeatIntervalMs: 30000
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Add a custom handler for when websocket reconnects
window.addEventListener("phx:connect", () => {
  // Check if there's a stored ID to help resync after disconnections
  const storedUserId = localStorage.getItem(window.POMODORO_USER_ID_KEY);
  if (storedUserId) {
    // This will sync state after reconnection if needed
    setTimeout(() => {
      const container = document.getElementById("user-id-container");
      if (container && container.phxHookId) {
        const hook = liveSocket.getHookById(container.phxHookId);
        if (hook) {
          hook.pushEvent("user_id_from_storage", { user_id: storedUserId });
        }
      }
    }, 500); // Small delay to ensure hook is initialized
  }
});

