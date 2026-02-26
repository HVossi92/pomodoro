defmodule Pomodoro.Accounts.OauthIdentity do
  @moduledoc """
  Schema for OAuth provider identities linked to a user (anonymous session id).
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "oauth_identities" do
    field :user_id, :string
    field :provider, :string
    field :provider_uid, :string
    field :email, :string
    field :name, :string
    field :sync_enabled, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(identity, attrs) do
    identity
    |> cast(attrs, [:user_id, :provider, :provider_uid, :email, :name, :sync_enabled])
    |> validate_required([:user_id, :provider, :provider_uid])
    |> unique_constraint([:user_id, :provider])
  end
end
