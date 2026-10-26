defmodule PhoenixDDoS.RateLimit do
  @moduledoc false

  # Helper count & check over ETS Cachex

  @store :phoenix_ddos_store

  # batch update cache
  def batch_check(checkers) do
    Cachex.execute!(@store, fn cache -> do_batch_check(cache, checkers) end)
  end

  def do_batch_check(cache, checkers) do
    # read once per batch; wall clock (never negative) so windows are aligned
    now = System.os_time(:millisecond)

    checkers
    |> Enum.reduce(%{}, fn {id, key, period, allowed, decision_if_above}, acc ->
      wkey = window_key(key, period, now)
      {:ok, n} = Cachex.incr(cache, wkey)

      # new ? set ttl (2 periods, the entry is useless after its window anyway)
      if n == 1, do: Cachex.expire(cache, wkey, 2 * period)

      Map.put(acc, (n > allowed && decision_if_above) || :pass, {id, wkey})
    end)
  end

  def window_key(key, period_ms, now_ms), do: "#{key}_#{div(now_ms, period_ms)}"
end
