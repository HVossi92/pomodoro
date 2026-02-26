defmodule Pomodoro.Sessions do
  @moduledoc """
  Context for persisting pomodoro session counts per user per date.
  Returns canonical shape `[%{"date" => "YYYY-MM-DD", "count" => n}]` for SessionStats.
  """
  import Ecto.Query
  alias Pomodoro.Repo
  alias Pomodoro.SessionStats
  alias Pomodoro.Sessions.PomodoroSession

  @doc """
  Atomically increments the session count for user_id on the given date.
  Creates a new row if none exists, otherwise increments the existing count.

  ## Examples

      iex> Sessions.increment_session("user_1", ~D[2026-02-25])
      {:ok, %PomodoroSession{count: 1}}

      iex> Sessions.increment_session("user_1", ~D[2026-02-25])
      {:ok, %PomodoroSession{count: 2}}
  """
  def increment_session(user_id, date) when is_binary(user_id) and is_struct(date, Date) do
    date_str = Date.to_iso8601(date)

    sql = """
    INSERT INTO pomodoro_sessions (user_id, date, count, inserted_at, updated_at)
    VALUES (?, ?, 1, datetime('now'), datetime('now'))
    ON CONFLICT(user_id, date) DO UPDATE SET
      count = pomodoro_sessions.count + 1,
      updated_at = datetime('now')
    """

    case Repo.query(sql, [user_id, date_str]) do
      {:ok, _} ->
        case Repo.get_by(PomodoroSession, user_id: user_id, date: date) do
          nil -> {:error, :not_found}
          session -> {:ok, session}
        end
      {:error, _} = err ->
        err
    end
  end

  @doc """
  Merges client sessions with DB and persists. For each date, keeps the max count.
  Returns the merged sessions in canonical shape.
  """
  def merge_from_client(user_id, client_sessions) when is_binary(user_id) and is_list(client_sessions) do
    db_sessions = list_sessions(user_id)
    merged = SessionStats.merge_sessions(db_sessions, client_sessions)

    Enum.each(merged, fn %{"date" => date_str, "count" => count} ->
      merge_session_count(user_id, date_str, count)
    end)

    list_sessions(user_id)
  end

  defp merge_session_count(user_id, date_str, target_count) do
    sql = """
    INSERT INTO pomodoro_sessions (user_id, date, count, inserted_at, updated_at)
    VALUES (?, ?, ?, datetime('now'), datetime('now'))
    ON CONFLICT(user_id, date) DO UPDATE SET
      count = max(pomodoro_sessions.count, excluded.count),
      updated_at = datetime('now')
    """
    Repo.query(sql, [user_id, date_str, target_count])
  end

  @doc """
  Returns all sessions for the given user_id in canonical shape:
  `[%{"date" => "YYYY-MM-DD", "count" => n}, ...]` sorted by date descending.
  """
  def list_sessions(user_id) when is_binary(user_id) do
    from(s in PomodoroSession,
      where: s.user_id == ^user_id,
      order_by: [desc: s.date],
      select: %{date: s.date, count: s.count}
    )
    |> Repo.all()
    |> Enum.map(fn %{date: d, count: c} ->
      %{"date" => Date.to_iso8601(d), "count" => c}
    end)
  end

  @doc """
  Deletes all pomodoro session records for the given user_id.
  Used when a user requests deletion of their data (e.g. GDPR right to erasure).
  """
  def delete_all_sessions_for_user(user_id) when is_binary(user_id) do
    from(s in PomodoroSession, where: s.user_id == ^user_id)
    |> Repo.delete_all()
  end
end
