defmodule PomodoroWeb.PageControllerTest do
  use PomodoroWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Ready to focus?"
    assert html_response(conn, 200) =~ "Focus for 25 minutes, then take a short break."
  end
end
