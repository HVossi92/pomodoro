defmodule Pomodoro.Repo.Migrations.DropGistCredentials do
  use Ecto.Migration

  def change do
    drop_if_exists table(:gist_credentials)
  end
end
