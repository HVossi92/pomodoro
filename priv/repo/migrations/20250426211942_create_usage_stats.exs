defmodule Pomodoro.Repo.Migrations.CreateUsageStats do
  use Ecto.Migration

  def change do
    create table(:usage_stats) do
      add :anonymous_id, :string, null: false
      add :action, :string, null: false
      add :timer_mode, :string
      add :timer_duration, :integer

      timestamps()
    end

    # Index for faster queries on anonymous_id
    create index(:usage_stats, [:anonymous_id])
    # Index for faster queries for specific actions
    create index(:usage_stats, [:action])
  end
end
