defmodule Pomodoro.SessionStats do
  @moduledoc """
  Pure functions for session statistics: streak calculation, session merging,
  and heatmap data. Used by the session stats UI (streak, heatmap) and Gist sync.
  """

  @doc """
  Calculates the current streak (consecutive days with at least one completed focus session).

  Walks backward from `today`; if today has no sessions, returns 0. Otherwise
  counts consecutive days including today.

  ## Examples

      iex> SessionStats.calculate_streak([], ~D[2026-02-25])
      0

      iex> SessionStats.calculate_streak([%{date: "2026-02-25", count: 1}], ~D[2026-02-25])
      1

      iex> SessionStats.calculate_streak([
      ...>   %{date: "2026-02-25", count: 1},
      ...>   %{date: "2026-02-24", count: 2}
      ...> ], ~D[2026-02-25])
      2

      iex> SessionStats.calculate_streak([
      ...>   %{date: "2026-02-25", count: 1},
      ...>   %{date: "2026-02-23", count: 1}
      ...> ], ~D[2026-02-25])
      1
  """
  def calculate_streak(sessions, today \\ Date.utc_today())

  def calculate_streak([], _today), do: 0

  def calculate_streak(sessions, today) when is_struct(today, Date) do
    today_str = Date.to_iso8601(today)
    count_by_date = sessions_with_count(sessions)
    session_dates =
      count_by_date
      |> Enum.filter(fn {_date, count} -> count >= 1 end)
      |> Enum.map(&elem(&1, 0))
      |> MapSet.new()

    unless MapSet.member?(session_dates, today_str) do
      0
    else
      do_calculate_streak(session_dates, today, 0)
    end
  end

  defp do_calculate_streak(session_dates, date, acc) do
    date_str = Date.to_iso8601(date)

    if MapSet.member?(session_dates, date_str) do
      do_calculate_streak(session_dates, Date.add(date, -1), acc + 1)
    else
      acc
    end
  end

  @doc """
  Adds one completed session for the given date. Returns updated sessions list.

  If the date already exists, increments count. Otherwise appends a new entry with count 1.
  Dates are expected as "YYYY-MM-DD" strings.

  ## Examples

      iex> SessionStats.add_session([], "2026-02-25")
      [%{date: "2026-02-25", count: 1}]

      iex> SessionStats.add_session([%{date: "2026-02-25", count: 2}], "2026-02-25")
      [%{date: "2026-02-25", count: 3}]
  """
  def add_session(sessions, date) when is_binary(date) do
    case Enum.find_index(sessions, fn s -> s["date"] == date or (is_map(s) and Map.get(s, :date) == date) end) do
      nil ->
        sessions ++ [%{"date" => date, "count" => 1}]

      idx ->
        s = Enum.at(sessions, idx)
        count = get_count(s) + 1
        date_str = get_date(s)
        List.replace_at(sessions, idx, %{"date" => date_str, "count" => count})
    end
  end

  defp get_date(%{"date" => d}), do: d
  defp get_date(%{date: d}), do: to_string(d)
  defp get_count(%{"count" => c}), do: c
  defp get_count(%{count: c}), do: c

  @doc """
  Sanitizes client-provided session list. Keeps only maps with "date" (YYYY-MM-DD)
  and "count" (non-negative integer). Caps length at max_len (default 500).
  """
  def sanitize_sessions(raw, max_len \\ 500) when is_list(raw) and is_integer(max_len) do
    date_regex = ~r/\A\d{4}-\d{2}-\d{2}\z/

    raw
    |> Enum.take(max_len)
    |> Enum.filter(&is_map/1)
    |> Enum.map(fn
      %{"date" => d, "count" => c} when is_binary(d) and is_integer(c) and c >= 0 ->
        if d =~ date_regex, do: %{"date" => d, "count" => c}, else: nil
      %{date: d, count: c} when is_binary(d) and is_integer(c) and c >= 0 ->
        ds = to_string(d)
        if ds =~ date_regex, do: %{"date" => ds, "count" => c}, else: nil
      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Merges two session lists. For each date, takes the maximum count.

  ## Examples

      iex> SessionStats.merge_sessions([], [])
      []

      iex> SessionStats.merge_sessions(
      ...>   [%{"date" => "2026-02-25", "count" => 2}],
      ...>   [%{"date" => "2026-02-24", "count" => 1}]
      ...> )
      [%{"date" => "2026-02-25", "count" => 2}, %{"date" => "2026-02-24", "count" => 1}]

      iex> SessionStats.merge_sessions(
      ...>   [%{"date" => "2026-02-25", "count" => 2}],
      ...>   [%{"date" => "2026-02-25", "count" => 3}]
      ...> )
      [%{"date" => "2026-02-25", "count" => 3}]
  """
  def merge_sessions(local, remote) do
    by_date =
      (local ++ remote)
      |> Enum.group_by(&normalize_date/1, & &1)
      |> Enum.map(fn {date, list} ->
        max_count = list |> Enum.map(&get_count/1) |> Enum.max()
        %{"date" => date, "count" => max_count}
      end)

    Enum.sort_by(by_date, & &1["date"], :desc)
  end

  defp normalize_date(%{"date" => d}), do: d
  defp normalize_date(%{date: d}), do: to_string(d)

  @doc """
  Returns heatmap intensity bucket 0..4 for a given count (0 = none, 4 = 4+).
  """
  def heatmap_bucket(count) when is_integer(count) and count <= 0, do: 0
  def heatmap_bucket(1), do: 1
  def heatmap_bucket(2), do: 2
  def heatmap_bucket(3), do: 3
  def heatmap_bucket(_), do: 4

  @doc """
  Returns a map of date string => bucket (0..4) for the last 364 days ending at `today`.
  Used by the heatmap UI.
  """
  def heatmap_data(sessions, today \\ Date.utc_today()) do
    count_by_date =
      sessions
      |> sessions_with_count()
      |> Enum.into(%{})

    for day_offset <- 0..363 do
      d = Date.add(today, -day_offset)
      date_str = Date.to_iso8601(d)
      count = Map.get(count_by_date, date_str, 0)
      {date_str, heatmap_bucket(count)}
    end
    |> Enum.into(%{})
  end

  defp sessions_with_count(sessions) do
    Enum.map(sessions, fn s ->
      date = get_date(s)
      count = get_count(s)
      {date, count}
    end)
    |> Enum.into(%{})
  end
end
