defmodule PomodoroWeb.SettingsLiveTest do
  use PomodoroWeb.ConnCase

  alias Pomodoro.GistCredentials

  test "GET /settings", %{conn: conn} do
    conn = get(conn, ~p"/settings")
    assert html_response(conn, 200) =~ "Settings"
    assert html_response(conn, 200) =~ "GitHub Gist"
  end

  test "gist_disconnect removes credentials (user-initiated)", %{conn: conn} do
    conn = get(conn, ~p"/settings")
    user_id = get_session(conn, "pomodoro_user_id")
    assert user_id != nil

    GistCredentials.connect(user_id, "ghp_test", "gist_123")
    assert GistCredentials.connected?(user_id)

    {:ok, view, _html} = live(conn, ~p"/settings")
    render_hook(view, "gist_disconnect", %{})
    assert_push_event(view, "gist_disconnect_result", %{ok: true})

    refute GistCredentials.connected?(user_id)
  end

  test "gist_connect with existing credential preserves gist_id (re-connect, no new gist)", %{conn: conn} do
    conn = get(conn, ~p"/settings")
    user_id = get_session(conn, "pomodoro_user_id")
    assert user_id != nil

    GistCredentials.connect(user_id, "ghp_old_token", "existing_gist_456")
    assert GistCredentials.connected?(user_id)

    {:ok, view, _html} = live(conn, ~p"/settings")
    render_hook(view, "gist_connect", %{"token" => "ghp_new_token"})
    assert_push_event(view, "gist_connect_result", %{ok: true, gist_id: "existing_gist_456"})

    # Verify no need_data was sent (would trigger gist creation)
    refute_push_event(view, "gist_connect_result", %{need_data: true})

    # Verify credentials updated with new token but same gist_id
    creds = GistCredentials.get_credentials(user_id)
    assert creds.gist_id == "existing_gist_456"
  end
end
