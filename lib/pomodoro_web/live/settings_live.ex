defmodule PomodoroWeb.SettingsLive do
  @moduledoc """
  Settings page: GitHub Gist connection for backing up session stats.
  Token is stored encrypted on the server (BFF). User can connect or disconnect.
  """
  use PomodoroWeb, :live_view
  alias Pomodoro.GistCredentials
  alias Pomodoro.GithubGist

  @impl true
  def mount(_params, session, socket) do
    user_id = PomodoroWeb.UserId.get_user_id(session)
    connected = GistCredentials.connected?(user_id)
    gist_id = if connected, do: get_gist_id(user_id), else: nil

    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(:user_id, user_id)
     |> assign(:gist_connected, connected)
     |> assign(:gist_id, gist_id)
     |> assign(:show_token_guide, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto">
      <h1 class="text-2xl font-bold text-gray-800 dark:text-gray-200 mb-6">Settings</h1>

      <div
        id="gist-settings"
        phx-hook="GistSettingsHook"
        class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow"
        data-gist-connected={@gist_connected}
        data-gist-id={@gist_id}
      >
        <div class="flex items-center gap-2 mb-2">
          <h2 class="text-lg font-semibold text-gray-700 dark:text-gray-300">
            GitHub Gist backup
          </h2>
          <button
            type="button"
            phx-click="show_token_guide"
            class="flex h-6 w-6 items-center justify-center rounded-full border border-gray-300 dark:border-gray-600 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-600 text-sm font-medium"
            aria-label="How to get a GitHub token"
          >
            ?
          </button>
        </div>
        <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
          Connect a personal access token (with <code class="bg-gray-100 dark:bg-gray-700 px-1 rounded">gist</code> scope) to back up your session data to a private Gist.
        </p>
        <input
          type="password"
          id="github-token-input"
          placeholder="ghp_..."
          class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200 px-3 py-2 mb-3 text-sm"
          autocomplete="off"
        />
        <div class="flex gap-3">
          <button
            type="button"
            id="gist-connect-btn"
            class="bg-red-600 hover:bg-red-700 text-white font-medium py-2 px-4 rounded-lg"
          >
            Connect
          </button>
          <button
            type="button"
            id="gist-disconnect-btn"
            class="bg-gray-200 hover:bg-gray-300 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200 font-medium py-2 px-4 rounded-lg"
          >
            Disconnect
          </button>
        </div>
        <p id="gist-status" class="mt-3 text-sm text-gray-500 dark:text-gray-400" role="status">
          —
        </p>
        <p class="mt-1 text-xs text-gray-400 dark:text-gray-500" aria-hidden="true">
          The gist ID is set automatically after a successful connection so the app can sync your sessions; it stays empty until then.
        </p>
      </div>
    </div>
    <%= if @show_token_guide do %>
      <.modal id="token-guide-modal" show={true} on_cancel={JS.push("close_token_guide")}>
        <div id="token-guide-modal-title" class="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-4">
          How to get a GitHub token for Gist backup
        </div>
        <div id="token-guide-modal-description" class="space-y-4 text-gray-700 dark:text-gray-300 text-sm">
          <ol class="list-decimal list-inside space-y-2">
            <li>
              Open
              <a
                href="https://github.com/settings/tokens/new?scopes=gist&description=Pomodoro+Gist+backup"
                target="_blank"
                rel="noopener noreferrer"
                class="text-red-600 dark:text-red-400 underline hover:no-underline"
              >
                GitHub → Settings → Developer settings → Personal access tokens → Generate new token (classic)
              </a>, or go to GitHub → your profile picture → Settings → Developer settings → Personal access tokens.
            </li>
            <li>Click <strong>Generate new token (classic)</strong> and give it a name (e.g. "Pomodoro Gist backup").</li>
            <li>Under scopes, check only <strong>gist</strong> (create, list, update, delete gists).</li>
            <li>Click <strong>Generate token</strong> and copy the token (it starts with <code class="bg-gray-100 dark:bg-gray-700 px-1 rounded">ghp_</code>).</li>
            <li>Paste the token into the field above and click <strong>Connect</strong>. Never share your token or commit it to a repo.</li>
          </ol>
          <p class="text-gray-500 dark:text-gray-400 pt-2">
            Your token is stored encrypted on our server and used only to create and update your private Gist. You can disconnect at any time in Settings.
          </p>
        </div>
      </.modal>
    <% end %>
    """
  end

  @impl true
  def handle_event("gist_connect", %{"token" => token}, socket) when is_binary(token) do
    token = String.trim(token)
    user_id = socket.assigns.user_id

    cond do
      token == "" ->
        {:noreply, push_event(socket, "gist_connect_result", %{ok: false, error: "Enter a token first."})}

      true ->
        existing = GistCredentials.get_credentials(user_id)

        if existing && existing.gist_id do
          # Re-connect: preserve existing gist, update token only (no new gist)
          case GistCredentials.connect(user_id, token, existing.gist_id) do
            {:ok, _cred} ->
              {:noreply,
               socket
               |> assign(:gist_connected, true)
               |> assign(:gist_id, existing.gist_id)
               |> push_event("gist_connect_result", %{ok: true, gist_id: existing.gist_id})}

            {:error, _} ->
              {:noreply, push_event(socket, "gist_connect_result", %{ok: false, error: "Failed to store credentials."})}
          end
        else
          # New connect: create gist with current session data from client (will be sent in payload)
          case GistCredentials.connect(user_id, token, nil) do
            {:ok, _cred} ->
              {:noreply, push_event(socket, "gist_connect_result", %{ok: true, need_data: true})}

            {:error, _} ->
              {:noreply, push_event(socket, "gist_connect_result", %{ok: false, error: "Failed to store credentials."})}
          end
        end
    end
  end

  @impl true
  def handle_event("gist_connect_with_data", %{"data" => data}, socket) do
    user_id = socket.assigns.user_id
    creds = GistCredentials.get_credentials(user_id)
    if is_nil(creds), do: raise "no credentials"

    case GithubGist.create(creds.token, data) do
      {:ok, gist_id} ->
        GistCredentials.set_gist_id(user_id, gist_id)
        {:noreply,
         socket
         |> assign(:gist_connected, true)
         |> assign(:gist_id, gist_id)
         |> push_event("gist_connect_result", %{ok: true, gist_id: gist_id})}

      {:error, msg} ->
        {:noreply, push_event(socket, "gist_connect_result", %{ok: false, error: msg})}
    end
  end

  @impl true
  def handle_event("show_token_guide", _, socket) do
    {:noreply, assign(socket, :show_token_guide, true)}
  end

  @impl true
  def handle_event("close_token_guide", _, socket) do
    {:noreply, assign(socket, :show_token_guide, false)}
  end

  @impl true
  def handle_event("gist_disconnect", _, socket) do
    user_id = socket.assigns.user_id
    GistCredentials.disconnect(user_id)

    {:noreply,
     socket
     |> assign(:gist_connected, false)
     |> assign(:gist_id, nil)
     |> push_event("gist_disconnect_result", %{ok: true})}
  end

  defp get_gist_id(user_id) do
    creds = GistCredentials.get_credentials(user_id)
    creds && creds.gist_id
  end
end
