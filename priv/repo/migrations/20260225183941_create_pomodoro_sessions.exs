defmodule Pomodoro.Repo.Migrations.CreatePomodoroSessions do
  use Ecto.Migration

  def change do
    create table(:pomodoro_sessions) do
      add :user_id, :string
      add :date, :date, null: false
      add :count, :integer, null: false, default: 0

      timestamps()
    end

    create index(:pomodoro_sessions, [:user_id, :date])
  end
end
