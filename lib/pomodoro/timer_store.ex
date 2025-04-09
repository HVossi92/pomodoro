defmodule Pomodoro.TimerStore do
  use GenServer

  # Default timeout for inactive sessions in milliseconds (30 minutes)
  @default_session_timeout 30 * 60 * 1000

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
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

  def cleanup_user_timer(user_id) do
    GenServer.cast(__MODULE__, {:cleanup_timer, user_id})
  end

  # Server callbacks

  @impl true
  def init(opts) do
    # Get session timeout from options or use default
    session_timeout = Keyword.get(opts, :session_timeout, @default_session_timeout)

    # Start the ticker process
    tick_ref = Process.send_after(self(), :tick, 1000)
    # Schedule the first cleanup of inactive sessions
    cleanup_ref = Process.send_after(self(), :cleanup_inactive_sessions, session_timeout)

    {:ok,
     %{
       timers: %{},
       tick_ref: tick_ref,
       cleanup_ref: cleanup_ref,
       session_timeout: session_timeout,
       last_activity: %{}
     }}
  end

  @impl true
  def handle_call({:get_timer, user_id}, _from, state) do
    timer = get_or_create_timer(state.timers, user_id)
    # Update last activity timestamp
    updated_activity = Map.put(state.last_activity, user_id, System.monotonic_time(:millisecond))

    {:reply, timer,
     %{state | timers: Map.put(state.timers, user_id, timer), last_activity: updated_activity}}
  end

  @impl true
  def handle_call({:toggle_focus, user_id, focus_time}, _from, state) do
    timer = get_or_create_timer(state.timers, user_id)
    running = if timer.mode == :focus and timer.running, do: false, else: true
    new_timer = %{timer | running: running, mode: :focus, seconds_left: focus_time}

    # Update last activity timestamp
    updated_activity = Map.put(state.last_activity, user_id, System.monotonic_time(:millisecond))

    Phoenix.PubSub.broadcast(Pomodoro.PubSub, "timer:#{user_id}", {:timer_update, new_timer})

    {:reply, new_timer,
     %{state | timers: Map.put(state.timers, user_id, new_timer), last_activity: updated_activity}}
  end

  @impl true
  def handle_call({:toggle_break, user_id, break_time}, _from, state) do
    timer = get_or_create_timer(state.timers, user_id)
    running = if timer.mode == :break and timer.running, do: false, else: true
    new_timer = %{timer | running: running, mode: :break, seconds_left: break_time}

    # Update last activity timestamp
    updated_activity = Map.put(state.last_activity, user_id, System.monotonic_time(:millisecond))

    Phoenix.PubSub.broadcast(Pomodoro.PubSub, "timer:#{user_id}", {:timer_update, new_timer})

    {:reply, new_timer,
     %{state | timers: Map.put(state.timers, user_id, new_timer), last_activity: updated_activity}}
  end

  @impl true
  def handle_cast({:cleanup_timer, user_id}, state) do
    # Remove the user's timer from state and last activity
    updated_timers = Map.delete(state.timers, user_id)
    updated_activity = Map.delete(state.last_activity, user_id)

    {:noreply, %{state | timers: updated_timers, last_activity: updated_activity}}
  end

  @impl true
  def handle_info(:tick, %{tick_ref: old_ref} = state) do
    # Cancel old timer reference if it exists
    if old_ref, do: Process.cancel_timer(old_ref)

    # Update all running timers
    updated_timers =
      Enum.reduce(state.timers, %{}, fn {user_id, timer}, acc ->
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

    # Clean up completed timers (at zero and not running)
    cleaned_timers = clean_completed_timers(updated_timers)

    # Schedule next tick
    new_ref = Process.send_after(self(), :tick, 1000)
    {:noreply, %{state | timers: cleaned_timers, tick_ref: new_ref}}
  end

  @impl true
  def handle_info(
        :cleanup_inactive_sessions,
        %{cleanup_ref: old_ref, session_timeout: timeout} = state
      ) do
    # Cancel old timer reference if it exists
    if old_ref, do: Process.cancel_timer(old_ref)

    current_time = System.monotonic_time(:millisecond)

    # Identify inactive sessions
    {active_sessions, inactive_sessions} =
      Enum.split_with(state.last_activity, fn {_user_id, last_active} ->
        current_time - last_active < timeout
      end)

    # Clean up inactive sessions
    inactive_user_ids = Enum.map(inactive_sessions, fn {user_id, _} -> user_id end)

    # Remove inactive timers
    updated_timers =
      Enum.reduce(inactive_user_ids, state.timers, fn user_id, timers ->
        Map.delete(timers, user_id)
      end)

    # Updated last activity to include only active sessions
    updated_activity = Map.new(active_sessions)

    # Schedule next cleanup
    new_ref = Process.send_after(self(), :cleanup_inactive_sessions, timeout)

    {:noreply,
     %{state | timers: updated_timers, last_activity: updated_activity, cleanup_ref: new_ref}}
  end

  defp get_or_create_timer(timers, user_id) do
    Map.get(timers, user_id, %{
      running: false,
      seconds_left: 25 * 60,
      mode: :focus
    })
  end

  # Helper function to clean up completed timers
  defp clean_completed_timers(timers) do
    Enum.filter(timers, fn {_user_id, timer} ->
      # Keep timers that are either running or not at zero
      timer.running || timer.seconds_left > 0
    end)
    |> Map.new()
  end
end
