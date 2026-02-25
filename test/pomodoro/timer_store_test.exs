defmodule Pomodoro.TimerStoreTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Tests for TimerStore. async: false because we rely on the shared TimerStore
  and PubSub and real-time tick.
  """

  test "broadcasts {:pomodoro_complete, user_id} when focus timer reaches zero" do
    user_id = "test_pomodoro_complete_#{System.unique_integer([:positive])}"
    Phoenix.PubSub.subscribe(Pomodoro.PubSub, "timer:#{user_id}")

    # Start focus with 1 second duration so it completes quickly
    Pomodoro.TimerStore.toggle_focus(user_id, 1)

    assert_receive {:timer_update, _}, 2_000
    assert_receive {:timer_update, %{seconds_left: 0, mode: :focus}}, 2_000
    assert_receive {:pomodoro_complete, ^user_id}, 2_000

    Phoenix.PubSub.unsubscribe(Pomodoro.PubSub, "timer:#{user_id}")
  end

  test "does not broadcast pomodoro_complete when break timer reaches zero" do
    user_id = "test_break_complete_#{System.unique_integer([:positive])}"
    Phoenix.PubSub.subscribe(Pomodoro.PubSub, "timer:#{user_id}")

    Pomodoro.TimerStore.toggle_break(user_id, 1)

    # Consume timer updates until we see seconds_left: 0
    receive_until_zero(user_id, 10)

    # We must not have received pomodoro_complete (break mode)
    refute_received {:pomodoro_complete, ^user_id}

    Phoenix.PubSub.unsubscribe(Pomodoro.PubSub, "timer:#{user_id}")
  end

  defp receive_until_zero(_user_id, 0), do: :ok

  defp receive_until_zero(user_id, n) do
    receive do
      {:timer_update, %{seconds_left: 0}} -> :ok
      _ -> receive_until_zero(user_id, n - 1)
    after
      2_000 -> :ok
    end
  end
end
