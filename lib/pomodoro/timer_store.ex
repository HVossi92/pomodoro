defmodule Pomodoro.TimerStore do
  use GenServer

  # Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_timer(user_id) do
    GenServer.call(__MODULE__, {:get_timer, user_id})
  end

  def toggle_focus(user_id, focus_time \\ 25 * 60) do
    GenServer.call(__MODULE__, {:toggle_focus, user_id, focus_time})
  end

  def toggle_break(user_id, break_time \\ 5 * 60) do
    GenServer.call(__MODULE__, {:toggle_break, user_id, break_time})
  end

  # Server callbacks

  @impl true
  def init(_) do
    # Start the ticker process
    Process.send_after(self(), :tick, 1000)
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get_timer, user_id}, _from, timers) do
    timer = get_or_create_timer(timers, user_id)
    {:reply, timer, Map.put(timers, user_id, timer)}
  end

  @impl true
  def handle_call({:toggle_focus, user_id, focus_time}, _from, timers) do
    timer = get_or_create_timer(timers, user_id)
    new_timer = %{timer | running: !timer.running, mode: :focus, seconds_left: focus_time}

    Phoenix.PubSub.broadcast(Pomodoro.PubSub, "timer:#{user_id}", {:timer_update, new_timer})
    {:reply, new_timer, Map.put(timers, user_id, new_timer)}
  end

  @impl true
  def handle_call({:toggle_break, user_id, break_time}, _from, timers) do
    timer = get_or_create_timer(timers, user_id)
    new_timer = %{timer | running: !timer.running, mode: :break, seconds_left: break_time}

    Phoenix.PubSub.broadcast(Pomodoro.PubSub, "timer:#{user_id}", {:timer_update, new_timer})
    {:reply, new_timer, Map.put(timers, user_id, new_timer)}
  end

  @impl true
  def handle_info(:tick, timers) do
    # Update all running timers
    updated_timers =
      Enum.reduce(timers, %{}, fn {user_id, timer}, acc ->
        updated_timer =
          if timer.running && timer.seconds_left > 0 do
            new_seconds = timer.seconds_left - 1
            new_timer = %{timer | seconds_left: new_seconds}

            # Broadcast update
            Phoenix.PubSub.broadcast(
              Pomodoro.PubSub,
              "timer:#{user_id}",
              {:timer_update, new_timer}
            )

            new_timer
          else
            timer
          end

        Map.put(acc, user_id, updated_timer)
      end)

    # Schedule next tick
    Process.send_after(self(), :tick, 1000)
    {:noreply, updated_timers}
  end

  defp get_or_create_timer(timers, user_id) do
    Map.get(timers, user_id, %{
      running: false,
      seconds_left: 25 * 60,
      mode: :focus
    })
  end
end
