defmodule PomodoroWeb.TimerLive do
  use PomodoroWeb, :live_view

  # 25 minutes in seconds
  @focus_time 25 * 60
  # 5 minutes in seconds
  @break_time 5 * 60

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        timer_running: false,
        seconds_left: @focus_time,
        timer_mode: :focus,
        timer_ref: nil
      )

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
    socket =
      case socket.assigns.timer_running do
        true -> stop_timer(socket)
        false -> start_timer(socket, :focus)
      end

    {:noreply, socket}
  end

  def handle_event("toggle_break", _, socket) do
    socket =
      case socket.assigns.timer_running do
        true -> stop_timer(socket)
        false -> start_timer(socket, :break)
      end

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    new_seconds_left = socket.assigns.seconds_left - 1

    socket =
      if new_seconds_left <= 0 do
        # Timer complete
        send_notification(socket.assigns.timer_mode)
        if socket.assigns.timer_ref, do: Process.cancel_timer(socket.assigns.timer_ref)

        assign(socket,
          seconds_left: 0,
          timer_running: false,
          timer_ref: nil
        )
      else
        # Continue timer
        timer_ref = Process.send_after(self(), :tick, 1000)

        assign(socket,
          seconds_left: new_seconds_left,
          timer_ref: timer_ref
        )
      end

    {:noreply, socket}
  end

  defp start_timer(socket, mode) do
    seconds =
      case mode do
        :focus -> @focus_time
        :break -> @break_time
      end

    seconds_left =
      if mode == socket.assigns.timer_mode, do: socket.assigns.seconds_left, else: seconds

    timer_ref = Process.send_after(self(), :tick, 1000)

    assign(socket,
      timer_running: true,
      seconds_left: seconds_left,
      timer_mode: mode,
      timer_ref: timer_ref
    )
  end

  defp stop_timer(socket) do
    if socket.assigns.timer_ref, do: Process.cancel_timer(socket.assigns.timer_ref)
    assign(socket, timer_running: false, timer_ref: nil)
  end

  defp format_time(seconds) do
    minutes = div(seconds, 60)
    seconds = rem(seconds, 60)
    "#{String.pad_leading("#{minutes}", 2, "0")}:#{String.pad_leading("#{seconds}", 2, "0")}"
  end

  defp send_notification(mode) do
    # This function could be expanded to play a sound, show a browser notification, etc.
    IO.puts("#{mode} time completed!")
  end
end
