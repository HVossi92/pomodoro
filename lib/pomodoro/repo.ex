defmodule Pomodoro.Repo do
  use Ecto.Repo,
    otp_app: :pomodoro,
    adapter: Ecto.Adapters.SQLite3
end
