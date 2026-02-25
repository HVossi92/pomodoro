defmodule Pomodoro.Repo.Migrations.CreateGistCredentials do
  use Ecto.Migration

  def change do
    create table(:gist_credentials) do
      add :user_id, :string, null: false
      add :encrypted_github_token, :string, null: false
      add :gist_id, :string

      timestamps()
    end

    create unique_index(:gist_credentials, [:user_id])
  end
end
