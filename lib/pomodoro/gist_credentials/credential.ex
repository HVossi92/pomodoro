defmodule Pomodoro.GistCredentials.Credential do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "gist_credentials" do
    field :user_id, :string
    field :encrypted_github_token, :string
    field :gist_id, :string

    timestamps()
  end

  @doc false
  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:user_id, :encrypted_github_token, :gist_id])
    |> validate_required([:user_id, :encrypted_github_token])
    |> unique_constraint(:user_id)
  end
end
