defmodule Pomodoro.Analytics.UsageStat do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "usage_stats" do
    field :anonymous_id, :string
    field :action, :string
    field :timer_mode, :string
    field :timer_duration, :integer

    timestamps()
  end

  @doc false
  def changeset(usage_stat, attrs) do
    usage_stat
    |> cast(attrs, [:anonymous_id, :action, :timer_mode, :timer_duration])
    |> validate_required([:anonymous_id, :action])
  end

  @doc """
  Returns count of distinct users who started a timer at least once
  """
  def count_active_users do
    from(u in __MODULE__,
      where: u.action == "start",
      select: count(fragment("DISTINCT ?", u.anonymous_id))
    )
  end
end
