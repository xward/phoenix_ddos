defmodule PhoenixDDoSTest do
  @moduledoc """
  All ddos test can't be run async
  """

  use ExUnit.Case, async: true
  use Plug.Test

  doctest PhoenixDDoS

  import PhoenixDDoS.DDOSUtils

  alias PhoenixDDoS.Test.TelemetryUtils

  @an_ip {1, 2, 3, 4}
  @an_ip_charlist @an_ip |> :inet.ntoa()
  @another_ip {1, 2, 3, 5}

  describe "call/2" do
    setup do
      Cachex.clear(:phoenix_ddos_store)
      Cachex.clear(:phoenix_ddos_jail)
      Application.put_env(:phoenix_ddos, :safelist_ips, [])
      Application.put_env(:phoenix_ddos, :blocklist_ips, [])
      flush_protections()

      # https://elixirforum.com/t/testing-and-telemetry-events-how-to-test-if-they-are-sent/28273
      :telemetry.attach(
        "unit_test_telemetry",
        [:phoenix_ddos, :jail, :new],
        &TelemetryUtils.handle_telemetry_event/4,
        nil
      )

      :ok
    end

    test "safelist_ips" do
      # let mix ip format
      Application.put_env(:phoenix_ddos, :safelist_ips, [
        @an_ip |> :inet.ntoa() |> List.to_string(),
        @another_ip |> :inet.ntoa()
      ])

      [
        {PhoenixDDoS.IpRateLimit, allowed: 0, period: {2, :second}}
      ]
      |> put_protections()

      run_ddos(conn(), :never_fail)
      run_ddos(conn(%{remote_ip: @another_ip}), :never_fail)
    end

    test "blocklist_ips" do
      Application.put_env(:phoenix_ddos, :blocklist_ips, [@an_ip |> :inet.ntoa()])
      PhoenixDDoS.Configure.init()

      run_ddos(conn(), :always_fail)
    end

    test "IpRateLimit with jail" do
      [
        {PhoenixDDoS.IpRateLimit, allowed: 10, period: {2, :second}}
      ]
      |> put_protections()

      assert_not_in_jail(@an_ip)
      run_ddos(conn(), assert_fail_after_request: 10)
      assert_in_jail(@an_ip)

      assert_receive {:telemetry_event, [:phoenix_ddos, :jail, :new], %{}, %{ip: @an_ip_charlist}}

      :timer.sleep(3000)
      # still blocked, even if we waited more than period
      run_ddos(conn(), :always_fail)
    end

    test "IpRateLimit multiple ip" do
      [
        {PhoenixDDoS.IpRateLimit, allowed: 10, period: {2, :second}}
      ]
      |> put_protections()

      run_ddos(conn(), assert_fail_after_request: 10)

      run_ddos(conn(%{remote_ip: @another_ip}), assert_fail_after_request: 10)
    end

    test "IpRateLimit throttle" do
      [
        {PhoenixDDoS.IpRateLimit, allowed: 10, period: {2, :second}, jail_time: nil}
      ]
      |> put_protections()

      run_ddos(conn(), assert_fail_after_request: 10)
      assert_not_in_jail(@an_ip)

      :timer.sleep(3000)
      # fresh quota
      run_ddos(conn(), assert_fail_after_request: 10)
    end

    test "IpRateLimit bench" do
      [
        {PhoenixDDoS.IpRateLimit, allowed: 10_000, period: {2, :second}},
        {PhoenixDDoS.IpRateLimitPerRequestPath,
         request_paths: ["/admin"], allowed: 3, period: {1, :minute}}
      ]
      |> put_protections()

      start = PhoenixDDoS.Time.now()
      run_ddos(conn(), assert_fail_after_request: 10_000)

      # ~ 30 ms per 10k
      assert PhoenixDDoS.Time.diff_ms(start) < 100
    end

    test "IpRateLimitPerRequestPath" do
      [
        {PhoenixDDoS.IpRateLimitPerRequestPath,
         request_paths: ["/admin/:id/dashboard", {:post, "/admin"}],
         allowed: 3,
         period: {1, :minute},
         jail_time: nil}
      ]
      |> put_protections()

      run_ddos(conn(%{request_path: "/admin/23/dashboard"}), assert_fail_after_request: 3)

      run_ddos(conn(%{request_path: "/admin", method: "POST"}), assert_fail_after_request: 3)

      run_ddos(conn(%{request_path: "/admin"}), :never_fail)

      run_ddos(conn(%{request_path: "/user"}), :never_fail)
    end

    test "IpRateLimitPerRequestPath shared quota along all paths" do
      [
        {PhoenixDDoS.IpRateLimitPerRequestPath,
         request_paths: ["/admin", "/user"],
         allowed: 3,
         shared: true,
         jail_time: nil,
         period: {1, :minute}}
      ]
      |> put_protections()

      run_ddos(conn(%{request_path: "/admin"}), assert_fail_after_request: 3)

      run_ddos(conn(%{request_path: "/user"}), :always_fail)
    end
  end

  defp conn(attr \\ %{}) do
    conn(:get, "/") |> Map.put(:remote_ip, @an_ip) |> Map.merge(attr)
  end
end
