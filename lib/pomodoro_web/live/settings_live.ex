defmodule PomodoroWeb.SettingsLive do
  @moduledoc """
  Settings page: account connection and optional sync preferences.
  Stats are stored in the database; OAuth (Google/GitHub) for cross-device sync.
  """
  use PomodoroWeb, :live_view

  alias Pomodoro.Accounts

  @impl true
  def mount(_params, session, socket) do
    user_id = PomodoroWeb.UserId.get_user_id(session)
    identities = Accounts.list_identities(user_id)

    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(:user_id, user_id)
     |> assign(:identities, identities)
     |> assign(:signed_in?, identities != [])}
  end

  @impl true
  def handle_event("unlink", %{"provider" => provider}, socket) do
    Accounts.unlink_identity(socket.assigns.user_id, provider)
    identities = Accounts.list_identities(socket.assigns.user_id)

    {:noreply,
     socket
     |> put_flash(:info, "Signed out from #{provider}.")
     |> assign(:identities, identities)
     |> assign(:signed_in?, identities != [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto">
      <h1 class="text-2xl font-bold text-gray-800 dark:text-gray-200 mb-6">Settings</h1>

      <div class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow">
        <h2 class="text-lg font-semibold text-gray-700 dark:text-gray-300 mb-2">
          Account & sync
        </h2>
        <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
          Your session stats are stored in the database. Sign in with Google or GitHub to link your account for optional cross-device sync.
        </p>

        <p class="text-xs text-gray-500 dark:text-gray-400 mb-4">
          By signing in you agree to our <a href={~p"/terms"} class="text-red-600 dark:text-red-400 hover:underline">Terms of Service</a> and <a href={~p"/privacy"} class="text-red-600 dark:text-red-400 hover:underline">Privacy Policy</a>.
        </p>

        <%= if not @signed_in? do %>
          <div class="flex flex-col gap-3">
            <a
              href={~p"/auth/google"}
              class="inline-flex items-center justify-center gap-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-600"
            >
              Sign in with Google
            </a>
            <a
              href={~p"/auth/github"}
              class="inline-flex items-center justify-center gap-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-600"
            >
              Sign in with GitHub
            </a>
          </div>
        <% end %>

        <%= if @identities != [] do %>
          <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-600">
            <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Linked accounts</p>
            <ul class="space-y-2 text-sm text-gray-500 dark:text-gray-400">
              <%= for i <- @identities do %>
                <li class="flex items-center justify-between gap-2">
                  <span><%= i.provider %> — <%= i.email || i.name || i.provider_uid %></span>
                  <button
                    type="button"
                    id={"unlink-#{i.provider}"}
                    phx-hook="Confirm"
                    data-confirm={"Sign out from " <> i.provider <> "? You can sign in again later."}
                    data-phx-event="unlink"
                    phx-value-provider={i.provider}
                    class="text-red-600 dark:text-red-400 hover:underline font-medium"
                  >
                    Sign out
                  </button>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>
      </div>

      <div class="mt-6 bg-white dark:bg-gray-800 rounded-xl p-6 shadow">
        <h2 class="text-lg font-semibold text-gray-700 dark:text-gray-300 mb-2">
          Delete my data
        </h2>
        <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
          Permanently delete all your session statistics (heatmap and streaks) and unlink any connected accounts. You will get a new anonymous session. This cannot be undone.
        </p>
        <form id="delete-my-data-form" action={~p"/settings/delete_my_data"} method="post" class="inline">
          <input type="hidden" name="_csrf_token" id="delete-my-data-csrf" value="" />
          <button
            type="button"
            onclick="if (confirm('Permanently delete all your data and start with a new session? This cannot be undone.')) { document.getElementById('delete-my-data-csrf').value = document.querySelector('meta[name=\'csrf-token\']')?.getAttribute('content') || ''; document.getElementById('delete-my-data-form').submit(); }"
            class="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 focus:ring-2 focus:ring-red-500 focus:ring-offset-2 dark:focus:ring-offset-gray-800"
          >
            Delete my data
          </button>
        </form>
      </div>
    </div>
    """
  end
end
