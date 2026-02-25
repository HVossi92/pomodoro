defmodule Mix.Tasks.Pomodoro.SessionStats.Seed do
  @shortdoc "Generates sample session stats JSON for localStorage (heatmap/streak testing)"
  @moduledoc """
  Outputs JSON matching the `pomodoro_session_stats` localStorage structure so you can
  paste it into the browser console to test the heatmap and streak UI.

  ## Usage

      mix pomodoro.session_stats.seed           # last 90 days, print to stdout
      mix pomodoro.session_stats.seed --days 30

  Then in the browser console (on the app page):

      localStorage.setItem('pomodoro_session_stats', '<paste output here>');
      location.reload();
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      args
      |> OptionParser.parse(strict: [days: :integer], aliases: [])

    days = opts[:days] || 90
    today = Date.utc_today()

    sessions =
      for offset <- 0..(days - 1) do
        date = Date.add(today, -offset) |> Date.to_iso8601()
        # Vary count: some days 0, most 1-3, occasional 4+
        count = if rem(offset, 7) == 0, do: 0, else: Enum.random(1..4)
        %{"date" => date, "count" => count}
      end
      |> Enum.filter(fn %{"count" => c} -> c > 0 end)
      |> Enum.sort_by(& &1["date"], :desc)

    data = %{
      "sessions" => sessions,
      "github_gist_id" => nil
    }

    json = Jason.encode!(data, pretty: true)
    Mix.shell().info(json)
  end
end
