defmodule PomodoroWeb.TimerLive do
  use PomodoroWeb, :live_view
  alias Pomodoro.TimerStore

  # 25 minutes in seconds
  @focus_time 25 * 60
  # 5 minutes in seconds
  @break_time 5 * 60

  def mount(_params, session, socket) do
    # Get user_id from session or generate a new one
    user_id = PomodoroWeb.UserId.get_user_id(session)

    if connected?(socket) do
      # Subscribe to timer updates for this user
      Phoenix.PubSub.subscribe(Pomodoro.PubSub, "timer:#{user_id}")
    end

    # Get initial timer state
    timer = TimerStore.get_timer(user_id)

    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:timer_running, timer.running)
      |> assign(:seconds_left, timer.seconds_left)
      |> assign(:timer_mode, timer.mode)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-[80vh]">
      <div class="bg-white shadow-lg rounded-xl p-10 max-w-md w-full text-center">
        <div class="mb-8">
          <h2 class="text-xl font-semibold text-gray-700 mb-4">Ready to focus?</h2>

          <div class="timer-display mb-6">
            <div class="text-7xl font-mono font-bold text-gray-800 tracking-widest">
              {format_time(@seconds_left)}
            </div>
          </div>

          <div class="flex justify-center space-x-4">
            <button
              phx-click="toggle_focus"
              class="bg-red-600 hover:bg-red-700 text-white font-medium py-3 px-8 rounded-lg transition duration-200 ease-in-out transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-opacity-50"
              disabled={@timer_mode != :focus}
            >
              {if @timer_running && @timer_mode == :focus, do: "Pause", else: "Focus"}
            </button>
            <button
              phx-click="toggle_break"
              class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-3 px-8 rounded-lg transition duration-200 ease-in-out transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-opacity-50"
              disabled={@timer_mode != :break && !(@seconds_left == 0 && @timer_mode == :focus)}
            >
              {if @timer_running && @timer_mode == :break, do: "Pause", else: "Break"}
            </button>
          </div>
        </div>

        <div class="text-sm text-gray-500">
          <p>Focus for 25 minutes, then take a short break.</p>
          <p>Stay productive with the Pomodoro Technique.</p>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("toggle_focus", _, socket) do
    timer = TimerStore.toggle_focus(socket.assigns.user_id)

    socket =
      socket
      |> assign(:timer_running, timer.running)
      |> assign(:timer_mode, timer.mode)

    {:noreply, socket}
  end

  def handle_event("toggle_break", _, socket) do
    timer = TimerStore.toggle_break(socket.assigns.user_id)

    socket =
      socket
      |> assign(:timer_running, timer.running)
      |> assign(:timer_mode, timer.mode)

    {:noreply, socket}
  end

  def handle_info({:timer_update, timer}, socket) do
    socket =
      socket
      |> assign(:timer_running, timer.running)
      |> assign(:seconds_left, timer.seconds_left)
      |> assign(:timer_mode, timer.mode)

    {:noreply, socket}
  end

  defp format_time(seconds) do
    minutes = div(seconds, 60)
    seconds = rem(seconds, 60)
    "#{String.pad_leading("#{minutes}", 2, "0")}:#{String.pad_leading("#{seconds}", 2, "0")}"
  end
end
