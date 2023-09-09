defmodule PhoenixDDOS.Cache do
  @moduledoc """
  Helper count & check over ETS Cachex
  """

  @store :phoenix_ddos_store

  @debug false

  def incr_check(key, window_ms, max) do
    {:ok, n} = Cachex.incr(@store, key)

    if @debug, do: IO.puts("#{key} #{n} #{max}")

    case n do
      1 ->
        {:ok, true} = Cachex.expire(@store, key, window_ms)
        false

      n when n > max ->
        true

      _ ->
        false
    end
  end
end
