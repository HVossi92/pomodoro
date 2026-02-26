defmodule PomodoroWeb.SettingsControllerTest do
  use PomodoroWeb.ConnCase, async: true

  alias Pomodoro.Accounts
  alias Pomodoro.Sessions

  test "POST /settings/delete_my_data deletes user data and redirects with new session", %{conn: conn} do
    conn = get(conn, ~p"/")
    user_id = get_session(conn, "pomodoro_user_id")

    Sessions.increment_session(user_id, ~D[2026-02-25])
    Accounts.link_identity(user_id, "google", "g_123", email: "test@example.com")

    assert Sessions.list_sessions(user_id) != []
    assert Accounts.list_identities(user_id) != []

    conn = post(conn, ~p"/settings/delete_my_data")

    assert redirected_to(conn) == ~p"/"
    assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "deleted"
    assert Sessions.list_sessions(user_id) == []
    assert Accounts.list_identities(user_id) == []
  end
end
