defmodule PomodoroWeb.TimerLiveTest do
  use PomodoroWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Ready to focus?"
    assert html_response(conn, 200) =~ "Focus for 25 minutes"
  end

  test "handle_info :pomodoro_complete pushes pomodoro-complete event", %{conn: conn} do
    conn = get(conn, ~p"/")
    {:ok, view, _html} = live(conn, ~p"/")
    send(view.pid, {:pomodoro_complete, "test_user_id"})
    assert_push_event(view, "pomodoro-complete", %{})
  end

  test "session stats panel is rendered", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "session-stats-panel"
  end

  test "session_stats_update with malformed input does not crash", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    render_hook(view, "session_stats_update", %{
      "sessions" => [%{"date" => nil, "count" => "x"}, %{"date" => "2026-02-25", "count" => 1}]
    })

    assert_push_event(view, "session-stats-update", %{streak: _, heatmap: _})
  end

  test "gist_fetch with no credentials pushes ok: false", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    render_hook(view, "gist_fetch", %{})

    assert_push_event(view, "gist_fetch_result", %{ok: false})
  end
end
