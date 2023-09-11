defmodule PhoenixDDoS.RateLimit do
  @moduledoc false

  # Helper count & check over ETS Cachex

  @store :phoenix_ddos_store

  alias PhoenixDDoS.Time

  @debug false

  # on_catch in :jail, :block
  def incr_check(key, period, allowed, on_catch) do
    {:ok, n} = Cachex.incr(@store, key)

    if @debug, do: IO.puts("#{key} #{n} #{allowed}")

    case n do
      1 ->
        {:ok, true} = Cachex.expire(@store, key, Time.period_to_msec(period))
        :pass

      n when n > allowed ->
        on_catch

      _ ->
        :pass
    end
  end
end
