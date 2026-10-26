defmodule PhoenixDDoS.IPTest do
  @moduledoc false

  use ExUnit.Case, async: false

  import Plug.Test
  import PhoenixDDoS.DDOSUtils

  alias PhoenixDDoS.IP

  setup do
    Application.delete_env(:phoenix_ddos, :ipv6_prefix)
    Application.put_env(:phoenix_ddos, :safelist_ips, [])
    Application.put_env(:phoenix_ddos, :blocklist_ips, [])
    flush_protections()

    on_exit(fn ->
      Application.delete_env(:phoenix_ddos, :ipv6_prefix)
      Application.put_env(:phoenix_ddos, :safelist_ips, [])
      Application.put_env(:phoenix_ddos, :blocklist_ips, [])
      flush_protections()
    end)
  end

  test "ipv6 addresses of the same /64 share a key" do
    assert IP.key({0x2001, 0xDB8, 0, 0, 1, 2, 3, 4}) == IP.key({0x2001, 0xDB8, 0, 0, 9, 9, 9, 9})
    assert IP.key({0x2001, 0xDB8, 0, 0, 1, 2, 3, 4}) == ~c"2001:db8::/64"
    refute IP.key({0x2001, 0xDB8, 0, 1, 1, 2, 3, 4}) == IP.key({0x2001, 0xDB8, 0, 0, 1, 2, 3, 4})
  end

  test "ipv6_prefix is configurable" do
    Application.put_env(:phoenix_ddos, :ipv6_prefix, 48)
    assert IP.key({0x2001, 0xDB8, 0, 1, 1, 2, 3, 4}) == ~c"2001:db8::/48"
    Application.put_env(:phoenix_ddos, :ipv6_prefix, 128)
    assert IP.key({0x2001, 0xDB8, 0, 0, 1, 2, 3, 4}) == ~c"2001:db8::1:2:3:4/128"
  end

  test "ipv4 and ipv4-mapped keys are the ipv4 form" do
    assert IP.key({1, 2, 3, 4}) == ~c"1.2.3.4"
    assert IP.key({0, 0, 0, 0, 0, 0xFFFF, 0x0606, 0x0606}) == ~c"6.6.6.6"
  end

  test "normalize!/1" do
    assert IP.normalize!("2001:DB8::1") == IP.normalize!("2001:db8::1")
    assert IP.normalize!("2001:db8::1") == ~c"2001:db8::/64"
    assert IP.normalize!(~c"1.2.3.4") == ~c"1.2.3.4"
    assert IP.normalize!("::ffff:6.6.6.6") == ~c"6.6.6.6"
    assert_raise ArgumentError, ~r/invalid IP/, fn -> IP.normalize!("not an ip") end
  end

  test "blocklist 6.6.6.6 also rejects ::ffff:6.6.6.6" do
    Application.put_env(:phoenix_ddos, :blocklist_ips, ["6.6.6.6"])
    flush_protections()

    conn(:get, "/")
    |> Map.put(:remote_ip, {0, 0, 0, 0, 0, 0xFFFF, 0x0606, 0x0606})
    |> call()
    |> assert_rejected()
  end

  test "ipv6 blocklist entry covers the whole prefix" do
    Application.put_env(:phoenix_ddos, :blocklist_ips, ["2001:db8::1"])
    flush_protections()

    conn(:get, "/")
    |> Map.put(:remote_ip, {0x2001, 0xDB8, 0, 0, 7, 7, 7, 7})
    |> call()
    |> assert_rejected()

    conn(:get, "/")
    |> Map.put(:remote_ip, {0x2001, 0xDB8, 0, 1, 7, 7, 7, 7})
    |> call()
    |> assert_allowed()
  end
end
