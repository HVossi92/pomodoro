defmodule PomodoroWeb.SettingsLiveTest do
  use PomodoroWeb.ConnCase

  test "GET /settings", %{conn: conn} do
    conn = get(conn, ~p"/settings")
    assert html_response(conn, 200) =~ "Settings"
    assert html_response(conn, 200) =~ "Account & sync"
  end
end
