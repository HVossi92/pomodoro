defmodule Pomodoro.GistCredentials do
  @moduledoc """
  Encrypted storage and retrieval of GitHub Gist credentials per user.
  Uses SECRET_KEY_BASE (from endpoint config) to derive encryption key — no extra env var.
  """
  import Ecto.Query
  alias Pomodoro.Repo
  alias Pomodoro.GistCredentials.Credential

  @aad "pomodoro-gist-v1"

  @doc """
  Connects a user's GitHub token: encrypts, stores, and optionally sets gist_id.
  Returns {:ok, gist_id} or {:error, changeset}.
  """
  def connect(user_id, plaintext_token, gist_id \\ nil) do
    case encrypt(plaintext_token) do
      {:ok, encrypted} ->
        attrs = %{
          user_id: user_id,
          encrypted_github_token: encrypted,
          gist_id: gist_id
        }

        %Credential{}
        |> Credential.changeset(attrs)
        |> Repo.insert(on_conflict: :replace_all, conflict_target: [:user_id])
      {:error, _} = err -> err
    end
  end

  @doc """
  Updates the stored gist_id for the user (e.g. after creating a new Gist).
  """
  def set_gist_id(user_id, gist_id) do
    case get_credential(user_id) do
      nil -> {:error, :not_found}
      cred ->
        cred
        |> Credential.changeset(%{gist_id: gist_id})
        |> Repo.update()
    end
  end

  @doc """
  Disconnects (deletes) credentials for the user. User-initiated only.
  """
  def disconnect(user_id) do
    from(c in Credential, where: c.user_id == ^user_id)
    |> Repo.delete_all()
    :ok
  end

  @doc """
  Returns the decrypted GitHub token and gist_id for the user, or nil if not found.
  """
  def get_credentials(user_id) do
    case get_credential(user_id) do
      nil -> nil
      cred ->
        case decrypt(cred.encrypted_github_token) do
          {:ok, token} -> %{token: token, gist_id: cred.gist_id}
          _ -> nil
        end
    end
  end

  @doc """
  Returns true if the user has connected a Gist.
  """
  def connected?(user_id) do
    get_credential(user_id) != nil
  end

  defp get_credential(user_id) do
    Repo.get_by(Credential, user_id: user_id)
  end

  defp encryption_secret do
    case Application.get_env(:pomodoro, :gist_encryption_secret) do
      nil ->
        base =
          Application.get_env(:pomodoro, PomodoroWeb.Endpoint)[:secret_key_base] ||
            raise "missing secret_key_base for gist encryption (set in endpoint config)"

        secret = Plug.Crypto.KeyGenerator.generate(base, "gist credentials")
        Application.put_env(:pomodoro, :gist_encryption_secret, secret, persistent: true)
        secret

      secret ->
        secret
    end
  end

  defp encrypt(plaintext) when is_binary(plaintext) do
    secret = encryption_secret()
    encrypted = Plug.Crypto.MessageEncryptor.encrypt(plaintext, @aad, secret, secret)
    {:ok, encrypted}
  rescue
    _ -> {:error, :encryption_failed}
  end

  defp decrypt(encrypted) when is_binary(encrypted) do
    secret = encryption_secret()
    Plug.Crypto.MessageEncryptor.decrypt(encrypted, @aad, secret, secret)
  rescue
    _ -> {:error, :decryption_failed}
  end
end
