defmodule Mix.Tasks.Pomodoro.Analytics.Query do
  @shortdoc "Prints analytics usage summary and optional per-day sessions or users"
  @moduledoc """
  Runs analytics queries and prints results.

  ## Usage

      mix pomodoro.analytics.query              # usage summary only
      mix pomodoro.analytics.query --sessions 7 # sessions by day (last 7 days)
      mix pomodoro.analytics.query --users 7   # active users by day (last 7 days)

  Replaces the previous script `scripts/analytics_query.exs`.
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} =
      args
      |> OptionParser.parse(
        strict: [sessions: :integer, users: :integer],
        aliases: []
      )

    if opts[:sessions] do
      print_sessions_by_day(opts[:sessions])
    end

    if opts[:users] do
      print_active_users_by_day(opts[:users])
    end

    if !opts[:sessions] && !opts[:users] do
      print_usage_summary()
    end
  end

  defp print_usage_summary do
    stats = Pomodoro.Analytics.get_usage_stats()

    Mix.shell().info("""

    ===== POMODORO USAGE SUMMARY =====

    Total unique users: #{stats.total_unique_users}
    Total focus sessions: #{stats.total_focus_sessions}
    Total break sessions: #{stats.total_break_sessions}

    ==================================
    """)
  end

  defp print_sessions_by_day(days) do
    result = Pomodoro.Analytics.sessions_by_day(days)

    Mix.shell().info("""

    ===== SESSIONS BY DAY (LAST #{days} DAYS) =====

    """)

    if Enum.empty?(result) do
      Mix.shell().info("No data available for the selected period.")
    else
      Enum.each(result, fn {date, count} ->
        Mix.shell().info("#{date}: #{count} sessions")
      end)
    end

    Mix.shell().info("""

    ==================================
    """)
  end

  defp print_active_users_by_day(days) do
    result = Pomodoro.Analytics.active_users_by_day(days)

    Mix.shell().info("""

    ===== ACTIVE USERS BY DAY (LAST #{days} DAYS) =====

    """)

    if Enum.empty?(result) do
      Mix.shell().info("No data available for the selected period.")
    else
      Enum.each(result, fn {date, count} ->
        Mix.shell().info("#{date}: #{count} active users")
      end)
    end

    Mix.shell().info("""

    ==================================
    """)
  end
end
