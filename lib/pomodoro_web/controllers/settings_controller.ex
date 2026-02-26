defmodule PomodoroWeb.SettingsController do
  @moduledoc """
  Controller for settings-related actions that require a full request/response
  (e.g. delete my data and clear session).
  """
  use PomodoroWeb, :controller

  alias Pomodoro.Accounts
  alias Pomodoro.Sessions
  alias Pomodoro.TimerStore

  def delete_my_data(conn, _params) do
    user_id = PomodoroWeb.UserId.get_user_id(conn)

    Sessions.delete_all_sessions_for_user(user_id)
    Accounts.delete_all_identities_for_user(user_id)
    TimerStore.cleanup_user_timer(user_id)

    conn
    |> clear_session()
    |> configure_session(drop: true)
    |> put_flash(:info, "Your data has been deleted. You now have a new anonymous session.")
    |> redirect(to: ~p"/?deleted=1")
  end
end
