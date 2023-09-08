defmodule PhoenixDDOS.IpCheck do
  @moduledoc """
  check if an ip ddos
  """

  def check(conn) do
    {window, count} = Application.get_env(:phoenix_ddos, :ip_rate_limit, {60, 1000})

    ip = conn.remote_ip |> :inet.ntoa()
    cache_key = "ip_#{ip}_count"

    case Cachex.incr(:phoenix_ddos_store, cache_key) do
      {:ok, 1} ->
        {:ok, true} = Cachex.expire(:phoenix_ddos_store, cache_key, :timer.seconds(window))
        :cont

      {:ok, n} when n > count ->
        :reject

      {:ok, _n} ->
        :cont
    end
  end
end
