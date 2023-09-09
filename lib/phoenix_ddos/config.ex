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
    |> Enum.each(fn module ->
      Cachex.put(
        :phoenix_ddos_config,
        module,
        module
        |> fetch()
        |> Enum.map(fn {_, cfg} -> module.prepare_config(cfg) end)
        |> List.flatten()
      )
    end)
  end

  def get!(module) do
    {:ok, cfg} = Cachex.get(:phoenix_ddos_config, module)
    cfg
  end

  def rand_id do
    :crypto.strong_rand_bytes(3) |> Base.encode64()
  end

  def period_to_msec({n, :second}), do: n * 1_000
  def period_to_msec({n, :minute}), do: n * 60_000
  def period_to_msec({n, :hour}), do: n * 3_600_000
  def period_to_msec({n, :day}), do: n * 24 * 3_600_000
  def period_to_msec(period), do: raise("Invalid configuration period #{period}")

  defp fetch(module) do
    Application.get_env(:phoenix_ddos, :protections)
    |> Enum.filter(fn {mod, _} -> mod == module end)
  end
end
