defmodule PomodoroWeb.TimerLive do
  use PomodoroWeb, :live_view
  alias Pomodoro.TimerStore
  alias Pomodoro.SessionStats
  alias Pomodoro.GistCredentials
  alias Pomodoro.GithubGist
  alias PomodoroWeb.RateLimit

  # 25 minutes in seconds
  @focus_time 25 * 60
  # 5 minutes in seconds
  @break_time 5 * 60
  @session_stats_scale_ms 5_000
  @session_stats_limit 10
  @max_sessions_length 500

  @impl true
  def mount(_params, session, socket) do
    # Get user_id from session
    user_id = PomodoroWeb.UserId.get_user_id(session)

    # Initial empty state
    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:timer_running, false)
      |> assign(:seconds_left, @focus_time)
      |> assign(:timer_mode, :focus)
      |> assign(:page_title, "Pomo Focus - Loading...")

    if connected?(socket) do
      # First unsubscribe to prevent duplicate messages if reconnecting
      Phoenix.PubSub.unsubscribe(Pomodoro.PubSub, "timer:#{user_id}")
      # Then subscribe to timer updates for this user
      Phoenix.PubSub.subscribe(Pomodoro.PubSub, "timer:#{user_id}")

      # Get persisted timer state
      timer = TimerStore.get_timer(user_id)

      # Update with current timer state
      {:ok,
       assign(socket,
         timer_running: timer.running,
         seconds_left: timer.seconds_left,
         timer_mode: timer.mode,
         page_title: "Pomo Focus - #{format_time(timer.seconds_left)}"
       )}
    else
      # Return with temporary state until connected
      {:ok, socket}
    end
  end

  @impl true
  def terminate(_reason, socket) do
    # Cleanup when LiveView process terminates
    if socket.assigns[:user_id] do
      # Unsubscribe from PubSub
      Phoenix.PubSub.unsubscribe(Pomodoro.PubSub, "timer:#{socket.assigns.user_id}")
    end

    :ok
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-[80vh]">
      <div
        class="bg-white dark:bg-gray-800 shadow-lg rounded-xl p-10 max-w-md w-full text-center"
        phx-hook="TimerTitleHook"
        id="timer-display"
        data-seconds-left={@seconds_left}
        data-running={@timer_running}
      >
        <div class="mb-8">
          <h2 class="text-xl font-semibold text-gray-700 dark:text-gray-300 mb-4">Ready to focus?</h2>

          <div class="timer-display mb-6">
            <div class="text-7xl font-mono font-bold text-gray-800 dark:text-gray-200 tracking-widest">
              {format_time(@seconds_left)}
            </div>
          </div>

          <div class="flex justify-center space-x-4">
            <button
              phx-click="toggle_focus"
              class="bg-red-600 hover:bg-red-700 text-white font-medium py-3 px-8 rounded-lg transition duration-200 ease-in-out transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-opacity-50"
            >
              {if @timer_running && @timer_mode == :focus, do: "Reset", else: "Focus"}
            </button>
            <button
              phx-click="toggle_break"
              class="bg-gray-200 hover:bg-gray-300 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200 font-medium py-3 px-8 rounded-lg transition duration-200 ease-in-out transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-opacity-50"
            >
              {if @timer_running && @timer_mode == :break, do: "Reset", else: "Break"}
            </button>
          </div>
        </div>

        <div class="text-sm text-gray-500 dark:text-gray-400">
          <p>Focus for 25 minutes, then take a short break.</p>
          <p>Stay productive with the Pomodoro Technique.</p>
        </div>
      </div>

      <div id="session-stats-panel" phx-hook="SessionStatsHook" phx-update="ignore" class="mt-8 w-full max-w-4xl">
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_focus", _, socket) do
    timer = TimerStore.toggle_focus(socket.assigns.user_id, @focus_time)

    socket =
      socket
      |> assign(:timer_running, timer.running)
      |> assign(:timer_mode, timer.mode)
      |> assign(:seconds_left, timer.seconds_left)
      |> assign(:page_title, "Pomo Focus - #{format_time(timer.seconds_left)}")
      |> push_event("timer-update", %{
        running: timer.running,
        seconds_left: timer.seconds_left
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_break", _, socket) do
    timer = TimerStore.toggle_break(socket.assigns.user_id, @break_time)

    socket =
      socket
      |> assign(:timer_running, timer.running)
      |> assign(:timer_mode, timer.mode)
      |> assign(:seconds_left, timer.seconds_left)
      |> assign(:page_title, "Pomo Focus - #{format_time(timer.seconds_left)}")
      |> push_event("timer-update", %{
        running: timer.running,
        seconds_left: timer.seconds_left
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("session_stats_update", params, socket) do
    user_id = socket.assigns.user_id
    key = "session_stats:#{user_id}"

    case RateLimit.hit(key, @session_stats_scale_ms, @session_stats_limit) do
      {:allow, _} ->
        sessions = SessionStats.sanitize_sessions(params["sessions"] || [], @max_sessions_length)
        today = Date.utc_today()
        streak = SessionStats.calculate_streak(sessions, today)
        heatmap = SessionStats.heatmap_data(sessions, today)

        {:noreply,
         push_event(socket, "session-stats-update", %{
           streak: streak,
           heatmap: heatmap
         })}

      {:deny, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("session_stats_merge", params, socket) do
    user_id = socket.assigns.user_id
    key = "session_stats:#{user_id}"

    case RateLimit.hit(key, @session_stats_scale_ms, @session_stats_limit) do
      {:allow, _} ->
        local = SessionStats.sanitize_sessions(params["local"] || [], @max_sessions_length)
        remote = SessionStats.sanitize_sessions(params["remote"] || [], @max_sessions_length)
        merged = SessionStats.merge_sessions(local, remote)
        {:noreply, push_event(socket, "session-stats-merge-result", %{"sessions" => merged})}

      {:deny, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("gist_fetch", _, socket) do
    user_id = socket.assigns.user_id
    creds = GistCredentials.get_credentials(user_id)

    result =
      if is_nil(creds) or is_nil(creds.gist_id) do
        %{ok: false, error: "not connected"}
      else
        case GithubGist.fetch(creds.token, creds.gist_id) do
          {:ok, data} -> %{ok: true, data: data}
          {:error, msg} -> %{ok: false, error: msg}
        end
      end

    {:noreply, push_event(socket, "gist_fetch_result", result)}
  end

  @impl true
  def handle_event("gist_update", %{"gist_id" => gist_id, "data" => data}, socket)
      when is_binary(gist_id) and is_map(data) do
    user_id = socket.assigns.user_id
    creds = GistCredentials.get_credentials(user_id)

    result =
      if is_nil(creds) do
        %{ok: false, error: "not connected"}
      else
        case GithubGist.update(creds.token, gist_id, data) do
          :ok -> %{ok: true}
          {:error, msg} -> %{ok: false, error: msg}
        end
      end

    {:noreply, push_event(socket, "gist_update_result", result)}
  end

  def handle_event("gist_update", _, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:timer_update, timer}, socket) do
    socket =
      socket
      |> assign(:timer_running, timer.running)
      |> assign(:seconds_left, timer.seconds_left)
      |> assign(:timer_mode, timer.mode)
      |> assign(:page_title, "Pomo Focus - #{format_time(timer.seconds_left)}")
      |> push_event("timer-update", %{
        running: timer.running,
        seconds_left: timer.seconds_left
      })

    {:noreply, socket}
  end

  @impl true
  def handle_info({:pomodoro_complete, _user_id}, socket) do
    {:noreply, push_event(socket, "pomodoro-complete", %{})}
  end

  defp format_time(seconds) do
    minutes = div(seconds, 60)
    seconds = rem(seconds, 60)
    "#{String.pad_leading("#{minutes}", 2, "0")}:#{String.pad_leading("#{seconds}", 2, "0")}"
  end
end
