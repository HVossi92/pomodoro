defmodule PomodoroWeb.RateLimitTest do
  use ExUnit.Case, async: false

  alias PomodoroWeb.RateLimit

  @key "test_rate_key_#{System.unique_integer([:positive])}"
  @scale_ms 1_000
  @limit 2

  test "allows requests under limit" do
    assert {:allow, 1} = RateLimit.hit(@key, @scale_ms, @limit)
    assert {:allow, 2} = RateLimit.hit(@key, @scale_ms, @limit)
  end

  test "denies request over limit" do
    key = "test_deny_#{System.unique_integer([:positive])}"
    assert {:allow, _} = RateLimit.hit(key, @scale_ms, @limit)
    assert {:allow, _} = RateLimit.hit(key, @scale_ms, @limit)
    assert {:deny, _} = RateLimit.hit(key, @scale_ms, @limit)
  end
end
