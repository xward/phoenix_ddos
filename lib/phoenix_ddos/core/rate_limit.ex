defmodule PhoenixDDoS.RateLimit do
  @moduledoc false

  # Helper count & check over ETS Cachex

  @store :phoenix_ddos_store

  # batch update cache
  def batch_check(checkers) do
    Cachex.execute!(@store, fn cache -> do_batch_check(cache, checkers) end)
  end

  def do_batch_check(cache, checkers) do
    checkers
    |> Enum.reduce(%{}, fn {id, key, period, allowed, decision_if_above}, acc ->
      {:ok, n} = Cachex.incr(cache, key)

      # new ? set ttl
      if n == 1, do: Cachex.expire(cache, key, period)

      # IO.puts("#{key} #{n}/#{allowed}")

      Map.put(acc, (n > allowed && decision_if_above) || :pass, id)
    end)
  end
end
