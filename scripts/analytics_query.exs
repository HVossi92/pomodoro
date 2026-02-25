# DEPRECATED: Use mix pomodoro.analytics.query instead.
# Load this file with `iex -S mix run scripts/analytics_query.exs`

# Helper functions to query analytics data
defmodule AnalyticsHelper do
  import Ecto.Query
  alias Pomodoro.Repo
  alias Pomodoro.Analytics
  alias Pomodoro.Analytics.UsageStat

  def print_usage_summary do
    stats = Analytics.get_usage_stats()

    IO.puts "\n===== POMODORO USAGE SUMMARY =====\n"
    IO.puts "Total unique users: #{stats.total_unique_users}"
    IO.puts "Total focus sessions: #{stats.total_focus_sessions}"
    IO.puts "Total break sessions: #{stats.total_break_sessions}"
    IO.puts "\n=================================="

    stats
  end

  def sessions_by_day(days \\ 7) do
    date_cutoff = Date.utc_today() |> Date.add(-days)

    query = from u in UsageStat,
      where: u.action == "start" and fragment("date(?)", u.inserted_at) >= ^date_cutoff,
      group_by: fragment("date(?)", u.inserted_at),
      select: {
        fragment("date(?)", u.inserted_at),
        count(u.id)
      },
      order_by: fragment("date(?)", u.inserted_at)

    result = Repo.all(query)

    IO.puts "\n===== SESSIONS BY DAY (LAST #{days} DAYS) =====\n"

    if Enum.empty?(result) do
      IO.puts "No data available for the selected period."
    else
      Enum.each(result, fn {date, count} ->
        IO.puts "#{date}: #{count} sessions"
      end)
    end

    IO.puts "\n=================================="

    result
  end

  def active_users_by_day(days \\ 7) do
    date_cutoff = Date.utc_today() |> Date.add(-days)

    query = from u in UsageStat,
      where: fragment("date(?)", u.inserted_at) >= ^date_cutoff,
      group_by: fragment("date(?)", u.inserted_at),
      select: {
        fragment("date(?)", u.inserted_at),
        count(fragment("DISTINCT ?", u.anonymous_id))
      },
      order_by: fragment("date(?)", u.inserted_at)

    result = Repo.all(query)

    IO.puts "\n===== ACTIVE USERS BY DAY (LAST #{days} DAYS) =====\n"

    if Enum.empty?(result) do
      IO.puts "No data available for the selected period."
    else
      Enum.each(result, fn {date, count} ->
        IO.puts "#{date}: #{count} active users"
      end)
    end

    IO.puts "\n=================================="

    result
  end
end

# Make helper functions easily available in IEx
:ok = Application.ensure_started(:pomodoro)
IO.puts "\nAnalyticsHelper module is available. Try these commands:"
IO.puts "- AnalyticsHelper.print_usage_summary()"
IO.puts "- AnalyticsHelper.sessions_by_day()"
IO.puts "- AnalyticsHelper.active_users_by_day()"
