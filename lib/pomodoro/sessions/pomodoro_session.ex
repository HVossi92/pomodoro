defmodule Pomodoro.Sessions.PomodoroSession do
  @moduledoc """
  Schema for pomodoro session counts per user per date.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "pomodoro_sessions" do
    field :user_id, :string
    field :date, :date
    field :count, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:user_id, :date, :count])
    |> validate_required([:user_id, :date])
    |> validate_number(:count, greater_than_or_equal_to: 0)
    |> unique_constraint([:user_id, :date])
  end
end
