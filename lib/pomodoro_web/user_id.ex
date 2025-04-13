defmodule PomodoroWeb.UserId do
  @session_key "pomodoro_user_id"
  @local_storage_key "pomodoro_user_id"

  def get_user_id(conn_or_session) do
    case get_from_session(conn_or_session) do
      nil -> generate_user_id()
      user_id -> user_id
    end
  end

  def put_user_id(conn, user_id) do
    Plug.Conn.put_session(conn, @session_key, user_id)
  end

  def local_storage_key, do: @local_storage_key

  defp get_from_session(conn) when is_map(conn) and is_map(conn.private) do
    Plug.Conn.get_session(conn, @session_key)
  end

  defp get_from_session(session) when is_map(session) do
    Map.get(session, @session_key)
  end

  defp get_from_session(_), do: nil

  defp generate_user_id do
    :crypto.strong_rand_bytes(20) |> Base.url_encode64(padding: false)
  end
end
