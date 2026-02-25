defmodule Pomodoro.SessionStatsTest do
  use ExUnit.Case, async: true

  alias Pomodoro.SessionStats

  describe "calculate_streak/2" do
    test "empty sessions returns 0" do
      assert SessionStats.calculate_streak([], ~D[2026-02-25]) == 0
    end

    test "today only with one session returns 1" do
      sessions = [%{"date" => "2026-02-25", "count" => 1}]
      assert SessionStats.calculate_streak(sessions, ~D[2026-02-25]) == 1
    end

    test "today and yesterday returns 2" do
      sessions = [
        %{"date" => "2026-02-25", "count" => 1},
        %{"date" => "2026-02-24", "count" => 2}
      ]
      assert SessionStats.calculate_streak(sessions, ~D[2026-02-25]) == 2
    end

    test "gap breaks streak" do
      sessions = [
        %{"date" => "2026-02-25", "count" => 1},
        %{"date" => "2026-02-23", "count" => 1}
      ]
      assert SessionStats.calculate_streak(sessions, ~D[2026-02-25]) == 1
    end

    test "today with no sessions returns 0" do
      sessions = [%{"date" => "2026-02-24", "count" => 1}]
      assert SessionStats.calculate_streak(sessions, ~D[2026-02-25]) == 0
    end

    test "long streak" do
      sessions =
        for d <- 0..6 do
          %{"date" => Date.add(~D[2026-02-25], -d) |> Date.to_iso8601(), "count" => 1}
        end

      assert SessionStats.calculate_streak(sessions, ~D[2026-02-25]) == 7
    end

    test "accepts atom-key sessions" do
      sessions = [%{date: "2026-02-25", count: 1}]
      assert SessionStats.calculate_streak(sessions, ~D[2026-02-25]) == 1
    end

    test "date with count 0 does not count for streak" do
      sessions = [
        %{"date" => "2026-02-25", "count" => 0},
        %{"date" => "2026-02-24", "count" => 1}
      ]
      assert SessionStats.calculate_streak(sessions, ~D[2026-02-25]) == 0
    end
  end

  describe "add_session/2" do
    test "new date appends with count 1" do
      assert SessionStats.add_session([], "2026-02-25") == [%{"date" => "2026-02-25", "count" => 1}]
    end

    test "existing date increments count" do
      sessions = [%{"date" => "2026-02-25", "count" => 2}]
      assert SessionStats.add_session(sessions, "2026-02-25") == [
               %{"date" => "2026-02-25", "count" => 3}
             ]
    end

    test "existing date with atom keys normalizes to string keys" do
      sessions = [%{date: "2026-02-25", count: 1}]
      assert SessionStats.add_session(sessions, "2026-02-25") == [
               %{"date" => "2026-02-25", "count" => 2}
             ]
    end
  end

  describe "merge_sessions/2" do
    test "empty inputs returns empty" do
      assert SessionStats.merge_sessions([], []) == []
    end

    test "disjoint dates concatenates" do
      local = [%{"date" => "2026-02-25", "count" => 2}]
      remote = [%{"date" => "2026-02-24", "count" => 1}]
      result = SessionStats.merge_sessions(local, remote)
      assert length(result) == 2
      assert Enum.any?(result, fn s -> s["date"] == "2026-02-25" and s["count"] == 2 end)
      assert Enum.any?(result, fn s -> s["date"] == "2026-02-24" and s["count"] == 1 end)
    end

    test "overlapping date takes max count" do
      local = [%{"date" => "2026-02-25", "count" => 2}]
      remote = [%{"date" => "2026-02-25", "count" => 3}]
      assert SessionStats.merge_sessions(local, remote) == [%{"date" => "2026-02-25", "count" => 3}]
    end

    test "one empty" do
      local = [%{"date" => "2026-02-25", "count" => 1}]
      assert SessionStats.merge_sessions(local, []) == [%{"date" => "2026-02-25", "count" => 1}]
      assert SessionStats.merge_sessions([], local) == [%{"date" => "2026-02-25", "count" => 1}]
    end
  end

  describe "heatmap_bucket/1" do
    test "0 and negative return 0" do
      assert SessionStats.heatmap_bucket(0) == 0
      assert SessionStats.heatmap_bucket(-1) == 0
    end

    test "1 2 3 return 1 2 3" do
      assert SessionStats.heatmap_bucket(1) == 1
      assert SessionStats.heatmap_bucket(2) == 2
      assert SessionStats.heatmap_bucket(3) == 3
    end

    test "4 and above return 4" do
      assert SessionStats.heatmap_bucket(4) == 4
      assert SessionStats.heatmap_bucket(5) == 4
      assert SessionStats.heatmap_bucket(100) == 4
    end
  end

  describe "heatmap_data/2" do
    test "returns 364 days of data" do
      data = SessionStats.heatmap_data([], ~D[2026-02-25])
      assert map_size(data) == 364
    end

    test "today has correct bucket for session count" do
      sessions = [%{"date" => "2026-02-25", "count" => 3}]
      data = SessionStats.heatmap_data(sessions, ~D[2026-02-25])
      assert data["2026-02-25"] == 3
    end

    test "no session gives bucket 0" do
      data = SessionStats.heatmap_data([], ~D[2026-02-25])
      assert data["2026-02-25"] == 0
    end

    test "count 5 maps to bucket 4" do
      sessions = [%{"date" => "2026-02-25", "count" => 5}]
      data = SessionStats.heatmap_data(sessions, ~D[2026-02-25])
      assert data["2026-02-25"] == 4
    end
  end

  describe "sanitize_sessions/2" do
    test "keeps valid maps with YYYY-MM-DD date and non-negative count" do
      raw = [
        %{"date" => "2026-02-25", "count" => 1},
        %{date: "2026-02-24", count: 2}
      ]
      out = SessionStats.sanitize_sessions(raw)
      assert length(out) == 2
      assert Enum.any?(out, fn s -> s["date"] == "2026-02-25" and s["count"] == 1 end)
      assert Enum.any?(out, fn s -> s["date"] == "2026-02-24" and s["count"] == 2 end)
    end

    test "filters out invalid date format" do
      raw = [%{"date" => "not-a-date", "count" => 1}, %{"date" => "2026-02-25", "count" => 1}]
      out = SessionStats.sanitize_sessions(raw)
      assert out == [%{"date" => "2026-02-25", "count" => 1}]
    end

    test "filters out negative count" do
      raw = [%{"date" => "2026-02-25", "count" => -1}, %{"date" => "2026-02-25", "count" => 0}]
      out = SessionStats.sanitize_sessions(raw)
      assert out == [%{"date" => "2026-02-25", "count" => 0}]
    end

    test "caps length at max_len" do
      raw = for i <- 1..600, do: %{"date" => "2026-01-#{String.pad_leading("#{rem(i, 28) + 1}", 2, "0")}", "count" => 1}
      out = SessionStats.sanitize_sessions(raw, 500)
      assert length(out) <= 500
    end
  end
end
