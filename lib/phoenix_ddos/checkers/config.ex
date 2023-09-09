defmodule PhoenixDDOS.Config do
  @moduledoc """
  Load, check and preprocess :phoenix_ddos configuration

  Since we need dynamic configuration, we can't preprocess at compilation
  """

  def init, do: reload()

  def reload do
    [
      PhoenixDDOS.IpRateLimit,
      PhoenixDDOS.IpRateLimitPerRequestPath
    ]
    |> Enum.each(fn mod ->
      Cachex.put(
        :phoenix_ddos_config,
        mod,
        mod
        |> fetch()
        |> Enum.map(fn {_, cfg} -> mod.prepare_config(cfg) end)
        |> List.flatten()
      )
    end)
  end

  def get!(key) do
    {:ok, cfg} = Cachex.get(:phoenix_ddos_config, key)
    cfg
  end

  def rand_id do
    :crypto.strong_rand_bytes(3) |> Base.encode64()
  end

  defp fetch(module) do
    Application.get_env(:phoenix_ddos, :protections)
    |> Enum.filter(fn {mod, _} -> mod == module end)
  end

  # {1, :minute} to 60_000
  def period_to_msec({n, :second}), do: n * 1_000
  def period_to_msec({n, :minute}), do: n * 60_000
  def period_to_msec({n, :hour}), do: n * 3_600_000
  def period_to_msec(period), do: raise("Invalid configuration period #{period}")
end