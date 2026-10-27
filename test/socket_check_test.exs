defmodule PhoenixDDoS.SocketCheckTest do
  @moduledoc false

  use ExUnit.Case, async: false

  import PhoenixDDoS.DDOSUtils

  alias PhoenixDDoS.Jail

  @ip {5, 5, 5, 5}

  setup do
    reset = fn ->
      Application.put_env(:phoenix_ddos, :safelist_ips, [])
      Application.put_env(:phoenix_ddos, :blocklist_ips, [])
      flush_protections()
      Cachex.clear(:phoenix_ddos_store)
      Cachex.clear(:phoenix_ddos_jail)
    end

    reset.()
    on_exit(reset)
  end

  defp use_protection(allowed) do
    put_protections([
      {PhoenixDDoS.IpRateLimit, allowed: allowed, period: {1, :minute}, jail_time: {1, :minute}}
    ])
  end

  defp counter(ip_key) do
    {:ok, keys} = Cachex.keys(:phoenix_ddos_store)
    keys |> Enum.filter(&String.contains?(&1, to_string(ip_key))) |> hd()
  end

  test "blocklisted ip is refused" do
    Application.put_env(:phoenix_ddos, :blocklist_ips, ["5.5.5.5"])
    flush_protections()
    assert PhoenixDDoS.check_socket_ip(@ip) == :error
    assert PhoenixDDoS.check_socket_ip({5, 5, 5, 6}) == :ok
  end

  test "jailed ip is refused" do
    use_protection(100)
    Jail.send(~c"5.5.5.5", {PhoenixDDoS.IpRateLimit, %{jail_time: {1, :minute}}})
    assert PhoenixDDoS.check_socket_ip(@ip) == :error
  end

  test "normal ip is accepted and the global ip counter increments" do
    use_protection(100)
    assert PhoenixDDoS.check_socket_ip(@ip) == :ok
    assert PhoenixDDoS.check_socket_ip(@ip) == :ok
    assert {:ok, 2} = Cachex.get(:phoenix_ddos_store, counter("5.5.5.5"))
  end

  test "safelisted ip is accepted even above the limit" do
    Application.put_env(:phoenix_ddos, :safelist_ips, ["5.5.5.5"])
    use_protection(1)
    for _ <- 1..5, do: assert(PhoenixDDoS.check_socket_ip(@ip) == :ok)
  end

  test "ip over the global rate limit is refused and jailed" do
    use_protection(2)
    assert PhoenixDDoS.check_socket_ip(@ip) == :ok
    assert PhoenixDDoS.check_socket_ip(@ip) == :ok
    assert PhoenixDDoS.check_socket_ip(@ip) == :error
    assert_in_jail(@ip)
    assert PhoenixDDoS.check_socket_ip(@ip) == :error
  end

  test "ip over a rate limit without jail is refused but not jailed" do
    put_protections([
      {PhoenixDDoS.IpRateLimit, allowed: 1, period: {1, :hour}, jail_time: nil}
    ])

    assert PhoenixDDoS.check_socket_ip(@ip) == :ok
    assert PhoenixDDoS.check_socket_ip(@ip) == :error
    assert_not_in_jail(@ip)
  end
end
