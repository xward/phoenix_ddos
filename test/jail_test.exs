defmodule PhoenixDDoS.JailTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias PhoenixDDoS.Jail

  doctest PhoenixDDoS.Jail

  setup do
    # the doctest reads the first configured protection; don't depend on other tests' leftovers
    PhoenixDDoS.DDOSUtils.put_protections([
      {PhoenixDDoS.IpRateLimit, allowed: 10, period: {1, :minute}, jail_time: {1, :minute}}
    ])

    Cachex.clear(:phoenix_ddos_jail)
    Cachex.clear(:phoenix_ddos_suspicious_ips)
    on_exit(fn -> Jail.bail_out(~c"9.9.9.9") end)
  end

  test "jail entry expires after jail_time" do
    Jail.send(~c"9.9.9.9", {PhoenixDDoS.IpRateLimit, %{jail_time: {1, :second}}})

    {:ok, ttl} = Cachex.ttl(:phoenix_ddos_jail, ~c"9.9.9.9")
    assert is_integer(ttl) and ttl <= 1_000

    Process.sleep(1_100)
    Cachex.purge(:phoenix_ddos_jail)
    refute Jail.in_jail?(~c"9.9.9.9")
  end

  test "suspicious ip marker has a 6h ttl" do
    Jail.send(~c"9.9.9.9", {PhoenixDDoS.IpRateLimit, %{jail_time: {1, :second}}})

    {:ok, ttl} = Cachex.ttl(:phoenix_ddos_suspicious_ips, ~c"9.9.9.9")
    assert is_integer(ttl) and ttl > :timer.hours(5)
  end

  test "suspicious_ip?/1 accepts a binary" do
    refute Jail.suspicious_ip?("9.9.9.9")
    Jail.send(~c"9.9.9.9", {PhoenixDDoS.IpRateLimit, %{jail_time: {1, :minute}}})
    assert Jail.suspicious_ip?("9.9.9.9")
    Jail.bail_out("9.9.9.9")
    refute Jail.suspicious_ip?("9.9.9.9")
  end
end
