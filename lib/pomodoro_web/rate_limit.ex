defmodule PomodoroWeb.RateLimit do
  @moduledoc """
  Rate limiting via Hammer (ETS backend). Used for LiveView events.
  """
  use Hammer, backend: :ets
end
