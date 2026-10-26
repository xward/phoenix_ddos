defmodule PhoenixDDoS.JailTest do
  @moduledoc false

  use ExUnit.Case, async: false

  import Plug.Test
  import PhoenixDDoS.DDOSUtils

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

  test "public api looks up the client key of an address" do
    put_protections([
      {PhoenixDDoS.IpRateLimit, allowed: 1, period: {1, :hour}, jail_time: {1, :minute}}
    ])

    on_exit(fn -> Jail.bail_out("2001:db8::/64") end)
    Cachex.clear(:phoenix_ddos_store)

    ipv6_conn = conn(:get, "/") |> Map.put(:remote_ip, {0x2001, 0xDB8, 0, 0, 5, 5, 5, 5})
    ipv6_conn |> call() |> assert_allowed()
    ipv6_conn |> call() |> assert_rejected()

    assert Jail.ips_in_jail() == ["2001:db8::/64"]
    assert Jail.in_jail?("2001:db8::1")
    assert Jail.in_jail?(~c"2001:db8::1")
    assert Jail.in_jail?({0x2001, 0xDB8, 0, 0, 0, 0, 0, 1})
    assert Jail.in_jail?("2001:db8::/64")
    assert Jail.suspicious_ip?("2001:db8::1")
    refute Jail.in_jail?("2001:db8:0:1::1")

    assert Jail.bail_out("2001:db8::1") == :ok
    refute Jail.in_jail?("2001:db8::1")
    refute Jail.suspicious_ip?("2001:db8::1")
  end

  test "ipv4-mapped address is looked up as its ipv4 form" do
    Jail.send(~c"9.9.9.9", {PhoenixDDoS.IpRateLimit, %{jail_time: {1, :minute}}})
    assert Jail.in_jail?("::ffff:9.9.9.9")
    Jail.bail_out({0, 0, 0, 0, 0, 0xFFFF, 0x0909, 0x0909})
    refute Jail.in_jail?("9.9.9.9")
  end

  test "suspicious_ip?/1 accepts a binary" do
    refute Jail.suspicious_ip?("9.9.9.9")
    Jail.send(~c"9.9.9.9", {PhoenixDDoS.IpRateLimit, %{jail_time: {1, :minute}}})
    assert Jail.suspicious_ip?("9.9.9.9")
    Jail.bail_out("9.9.9.9")
    refute Jail.suspicious_ip?("9.9.9.9")
  end
end
