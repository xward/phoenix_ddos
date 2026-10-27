defmodule PhoenixDDoS.SupervisorTest do
  use ExUnit.Case, async: false

  setup do
    old_max = Application.fetch_env(:phoenix_ddos, :max_entries)
    old_jail = Application.fetch_env(:phoenix_ddos, :max_jail_entries)

    Application.put_env(:phoenix_ddos, :max_entries, 1_000)
    Application.put_env(:phoenix_ddos, :max_jail_entries, 100)
    restart()

    on_exit(fn ->
      restore(:max_entries, old_max)
      restore(:max_jail_entries, old_jail)
      restart()
    end)
  end

  defp restore(key, {:ok, v}), do: Application.put_env(:phoenix_ddos, key, v)
  defp restore(key, :error), do: Application.delete_env(:phoenix_ddos, key)

  defp restart do
    Application.stop(:phoenix_ddos)
    {:ok, _} = Application.ensure_all_started(:phoenix_ddos)
  end

  # the limit hook prunes on a schedule (every second): poll until it has run
  defp wait_size_within(cache, max, deadline \\ System.monotonic_time(:millisecond) + 3_000) do
    {:ok, size} = Cachex.size(cache)

    cond do
      size <= max ->
        size

      System.monotonic_time(:millisecond) > deadline ->
        size

      true ->
        Process.sleep(50)
        wait_size_within(cache, max, deadline)
    end
  end

  test "store is bounded" do
    for i <- 1..5_000, do: Cachex.put(:phoenix_ddos_store, i, true)
    assert wait_size_within(:phoenix_ddos_store, 1_000) <= 1_000
  end

  test "jail and suspicious ips are bounded by max_jail_entries" do
    for i <- 1..500 do
      Cachex.put(:phoenix_ddos_jail, i, true)
      Cachex.put(:phoenix_ddos_suspicious_ips, i, true)
    end

    assert wait_size_within(:phoenix_ddos_jail, 100) <= 100
    assert wait_size_within(:phoenix_ddos_suspicious_ips, 100) <= 100
  end
end
