defmodule Pomodoro.Accounts do
  @moduledoc """
  Context for OAuth identities and account linking.
  Links provider identities to anonymous user_id (session).
  """
  import Ecto.Query
  alias Pomodoro.Repo
  alias Pomodoro.Accounts.OauthIdentity

  @doc """
  Links an OAuth identity to the given user_id.
  Upserts by user_id + provider.
  """
  def link_identity(user_id, provider, provider_uid, opts \\ []) do
    email = Keyword.get(opts, :email)
    name = Keyword.get(opts, :name)
    sync_enabled = Keyword.get(opts, :sync_enabled, false)

    attrs = %{
      user_id: user_id,
      provider: to_string(provider),
      provider_uid: to_string(provider_uid),
      email: email,
      name: name,
      sync_enabled: sync_enabled
    }

    %OauthIdentity{}
    |> OauthIdentity.changeset(attrs)
    |> Repo.insert(on_conflict: {:replace, [:provider_uid, :email, :name, :updated_at]}, conflict_target: [:user_id, :provider])
  end

  @doc """
  Returns the OAuth identity for user_id and provider, or nil.
  """
  def get_identity(user_id, provider) when is_binary(user_id) and is_binary(provider) do
    Repo.get_by(OauthIdentity, user_id: user_id, provider: provider)
  end

  @doc """
  Returns all linked identities for the user.
  """
  def list_identities(user_id) when is_binary(user_id) do
    from(i in OauthIdentity, where: i.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Unlinks the identity for user_id and provider.
  """
  def unlink_identity(user_id, provider) do
    from(i in OauthIdentity, where: i.user_id == ^user_id and i.provider == ^provider)
    |> Repo.delete_all()
    :ok
  end

  @doc """
  Deletes all OAuth identities for the given user_id.
  Used when a user requests full deletion of their data (e.g. GDPR right to erasure).
  """
  def delete_all_identities_for_user(user_id) when is_binary(user_id) do
    from(i in OauthIdentity, where: i.user_id == ^user_id)
    |> Repo.delete_all()
    :ok
  end

  @doc """
  Toggles sync_enabled for the identity.
  """
  def set_sync_enabled(user_id, provider, enabled) do
    case get_identity(user_id, provider) do
      nil -> {:error, :not_found}
      identity ->
        identity
        |> OauthIdentity.changeset(%{sync_enabled: enabled})
        |> Repo.update()
    end
  end
end
