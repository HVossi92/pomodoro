defmodule PomodoroWeb.AuthController do
  @moduledoc """
  OAuth callback controller. Links provider identity to session user_id.
  """
  use PomodoroWeb, :controller

  plug Ueberauth

  alias Pomodoro.Accounts

  def request(conn, _params) do
    # Ueberauth strategy handles redirect to provider
    conn
  end

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Could not sign in: #{inspect(fails.errors)}")
    |> redirect(to: ~p"/settings")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_id = PomodoroWeb.UserId.get_user_id(conn)
    provider = to_string(auth.provider)
    provider_uid = auth.uid
    email = auth.info.email
    name = auth.info.name

    case Accounts.link_identity(user_id, provider, provider_uid, email: email, name: name) do
      {:ok, _identity} ->
        conn
        |> put_flash(:info, "Signed in with #{provider}.")
        |> redirect(to: ~p"/settings")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Could not link account: #{inspect(changeset.errors)}")
        |> redirect(to: ~p"/settings")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Signed out.")
    |> redirect(to: ~p"/")
  end
end
