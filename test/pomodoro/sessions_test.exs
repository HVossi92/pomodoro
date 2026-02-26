defmodule Pomodoro.SessionsTest do
  use Pomodoro.DataCase, async: true

  alias Pomodoro.Sessions

  describe "increment_session/2" do
    test "creates new row when none exists" do
      user_id = "user_#{System.unique_integer([:positive])}"
      date = ~D[2026-02-25]

      assert {:ok, session} = Sessions.increment_session(user_id, date)
      assert session.user_id == user_id
      assert session.date == date
      assert session.count == 1
    end

    test "increments count when row exists for user_id + date" do
      user_id = "user_#{System.unique_integer([:positive])}"
      date = ~D[2026-02-25]

      assert {:ok, s1} = Sessions.increment_session(user_id, date)
      assert s1.count == 1

      assert {:ok, s2} = Sessions.increment_session(user_id, date)
      assert s2.count == 2

      assert {:ok, s3} = Sessions.increment_session(user_id, date)
      assert s3.count == 3
    end
  end

  describe "list_sessions/1" do
    test "returns empty list for unknown user" do
      assert Sessions.list_sessions("nonexistent_user_#{System.unique_integer([:positive])}") == []
    end

    test "returns sessions in canonical shape sorted by date desc" do
      user_id = "user_#{System.unique_integer([:positive])}"

      Sessions.increment_session(user_id, ~D[2026-02-24])
      Sessions.increment_session(user_id, ~D[2026-02-25])
      Sessions.increment_session(user_id, ~D[2026-02-25])

      sessions = Sessions.list_sessions(user_id)

      assert length(sessions) == 2
      assert sessions == [
               %{"date" => "2026-02-25", "count" => 2},
               %{"date" => "2026-02-24", "count" => 1}
             ]
    end

    test "isolates data per user_id" do
      user_a = "user_a_#{System.unique_integer([:positive])}"
      user_b = "user_b_#{System.unique_integer([:positive])}"
      date = ~D[2026-02-25]

      Sessions.increment_session(user_a, date)
      Sessions.increment_session(user_a, date)
      Sessions.increment_session(user_b, date)

      assert Sessions.list_sessions(user_a) == [%{"date" => "2026-02-25", "count" => 2}]
      assert Sessions.list_sessions(user_b) == [%{"date" => "2026-02-25", "count" => 1}]
    end
  end

  describe "merge_from_client/2" do
    test "merges client sessions with DB and persists" do
      user_id = "user_#{System.unique_integer([:positive])}"

      Sessions.increment_session(user_id, ~D[2026-02-25])
      Sessions.increment_session(user_id, ~D[2026-02-25])

      client_sessions = [
        %{"date" => "2026-02-24", "count" => 3},
        %{"date" => "2026-02-25", "count" => 5}
      ]

      result = Sessions.merge_from_client(user_id, client_sessions)

      assert Enum.any?(result, fn s -> s["date"] == "2026-02-25" and s["count"] >= 5 end)
      assert Enum.any?(result, fn s -> s["date"] == "2026-02-24" and s["count"] == 3 end)
    end
  end

  describe "delete_all_sessions_for_user/1" do
    test "deletes all sessions for the given user" do
      user_id = "user_#{System.unique_integer([:positive])}"
      other_id = "user_#{System.unique_integer([:positive])}"

      Sessions.increment_session(user_id, ~D[2026-02-24])
      Sessions.increment_session(user_id, ~D[2026-02-25])
      Sessions.increment_session(other_id, ~D[2026-02-25])

      assert {2, _} = Sessions.delete_all_sessions_for_user(user_id)
      assert Sessions.list_sessions(user_id) == []
      assert Sessions.list_sessions(other_id) == [%{"date" => "2026-02-25", "count" => 1}]
    end

    test "returns {0, nil} for user with no sessions" do
      user_id = "user_#{System.unique_integer([:positive])}"
      assert {0, _} = Sessions.delete_all_sessions_for_user(user_id)
    end
  end
end
