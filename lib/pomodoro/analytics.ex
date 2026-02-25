defmodule Pomodoro.Analytics do
  @moduledoc """
  The Analytics context.
  Provides functions for tracking and analyzing timer usage.
  """

  import Ecto.Query
  alias Pomodoro.Repo
  alias Pomodoro.Analytics.UsageStat

  @doc """
  Logs a timer action without tracking personal information.
  """
  def log_action(anonymous_id, action, mode, duration) do
    try do
      %UsageStat{}
      |> UsageStat.changeset(%{
        anonymous_id: anonymous_id,
        action: to_string(action),
        timer_mode: to_string(mode),
        timer_duration: duration
      })
      |> Repo.insert()
    rescue
      e ->
        require Logger
        Logger.error("Failed to log analytics action: #{inspect(e)}")
        {:error, :analytics_failure}
    end
  end

  @doc """
  Returns the count of unique users who have used the timer.
  """
  def count_unique_users do
    try do
      query =
        from(u in UsageStat,
          where: u.action == "start",
          select: count(fragment("DISTINCT ?", u.anonymous_id))
        )

      Repo.one(query)
    rescue
      _ -> 0
    end
  end

  @doc """
  Gets basic usage statistics for the app.
  """
  def get_usage_stats do
    try do
      total_users =
        from(u in UsageStat,
          select: count(fragment("DISTINCT ?", u.anonymous_id))
        )
        |> Repo.one() || 0

      total_focus_sessions =
        from(u in UsageStat,
          where: u.action == "start" and u.timer_mode == "focus",
          select: count(u.id)
        )
        |> Repo.one() || 0

      total_break_sessions =
        from(u in UsageStat,
          where: u.action == "start" and u.timer_mode == "break",
          select: count(u.id)
        )
        |> Repo.one() || 0

      %{
        total_unique_users: total_users,
        total_focus_sessions: total_focus_sessions,
        total_break_sessions: total_break_sessions
      }
    rescue
      e ->
        require Logger
        Logger.error("Failed to get usage stats: #{inspect(e)}")

        %{
          total_unique_users: 0,
          total_focus_sessions: 0,
          total_break_sessions: 0
        }
    end
  end

  @doc """
  Returns sessions (timer starts) grouped by day for the last `days` days.
  Returns a list of `{date, count}`.
  """
  def sessions_by_day(days \\ 7) do
    date_cutoff = Date.utc_today() |> Date.add(-days)

    query =
      from(u in UsageStat,
        where: u.action == "start" and fragment("date(?)", u.inserted_at) >= ^date_cutoff,
        group_by: fragment("date(?)", u.inserted_at),
        select: {fragment("date(?)", u.inserted_at), count(u.id)},
        order_by: fragment("date(?)", u.inserted_at)
      )

    Repo.all(query)
  end

  @doc """
  Returns active users (distinct anonymous_id) per day for the last `days` days.
  Returns a list of `{date, count}`.
  """
  def active_users_by_day(days \\ 7) do
    date_cutoff = Date.utc_today() |> Date.add(-days)

    query =
      from(u in UsageStat,
        where: fragment("date(?)", u.inserted_at) >= ^date_cutoff,
        group_by: fragment("date(?)", u.inserted_at),
        select: {fragment("date(?)", u.inserted_at), count(fragment("DISTINCT ?", u.anonymous_id))},
        order_by: fragment("date(?)", u.inserted_at)
      )

    Repo.all(query)
  end
end
