defmodule Pomodoro.Repo.Migrations.AddUniqueIndexPomodoroSessions do
  use Ecto.Migration

  def change do
    drop_if_exists index(:pomodoro_sessions, [:user_id, :date])
    create unique_index(:pomodoro_sessions, [:user_id, :date])
  end
end
