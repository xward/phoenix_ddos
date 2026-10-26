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

  test "store is bounded" do
    for i <- 1..5_000, do: Cachex.put(:phoenix_ddos_store, i, true)
    Process.sleep(1_100)
    assert {:ok, size} = Cachex.size(:phoenix_ddos_store)
    assert size <= 1_000
  end

  test "jail and suspicious ips are bounded by max_jail_entries" do
    for i <- 1..500 do
      Cachex.put(:phoenix_ddos_jail, i, true)
      Cachex.put(:phoenix_ddos_suspicious_ips, i, true)
    end

    Process.sleep(1_100)
    assert {:ok, jail} = Cachex.size(:phoenix_ddos_jail)
    assert {:ok, sus} = Cachex.size(:phoenix_ddos_suspicious_ips)
    assert jail <= 100
    assert sus <= 100
  end
end
