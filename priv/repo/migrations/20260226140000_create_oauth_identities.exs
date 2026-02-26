defmodule Pomodoro.Repo.Migrations.CreateOauthIdentities do
  use Ecto.Migration

  def change do
    create table(:oauth_identities) do
      add :user_id, :string, null: false
      add :provider, :string, null: false
      add :provider_uid, :string, null: false
      add :email, :string
      add :name, :string
      add :sync_enabled, :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:oauth_identities, [:user_id, :provider])
    create index(:oauth_identities, [:provider, :provider_uid])
  end
end
