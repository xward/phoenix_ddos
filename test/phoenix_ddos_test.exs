defmodule PhoenixDDOSTest do
  @moduledoc """
  All ddos test can't be run async
  """

  use ExUnit.Case, async: true
  use Plug.Test

  doctest PhoenixDDOS

  import PhoenixDDOS.DDOSUtils

  @an_ip {1, 2, 3, 4}
  @another_ip {1, 2, 3, 5}

  describe "call/2" do
    setup do
      Cachex.clear(:phoenix_ddos_store)
      Cachex.clear(:phoenix_ddos_jail)
      :ok
    end

    test "IpRateLimit with jail" do
      [
        {PhoenixDDOS.IpRateLimit, allowed: 10, period: {2, :second}}
      ]
      |> put_protections()

      conn = %Plug.Conn{remote_ip: @an_ip}
      assert_not_in_jail(@an_ip)

      run_ddos(conn, 10)
      assert_in_jail(@an_ip)

      :timer.sleep(3000)
      # still blocked, even if we waited more than period
      run_ddos(conn, 0)
    end

    test "IpRateLimit multiple ip" do
      [
        {PhoenixDDOS.IpRateLimit, allowed: 10, period: {2, :second}}
      ]
      |> put_protections()

      conn = %Plug.Conn{remote_ip: @an_ip}
      run_ddos(conn, 10)

      conn = %Plug.Conn{remote_ip: @another_ip}
      run_ddos(conn, 10)
    end

    test "IpRateLimit thottle" do
      [
        {PhoenixDDOS.IpRateLimit, allowed: 10, period: {2, :second}, jail_time: nil}
      ]
      |> put_protections()

      conn = %Plug.Conn{remote_ip: @an_ip}
      run_ddos(conn, 10)
      assert_not_in_jail(@an_ip)

      :timer.sleep(3000)
      # fresh quota
      run_ddos(conn, 10)
    end

    test "IpRateLimit bench" do
      [
        {PhoenixDDOS.IpRateLimit, allowed: 10_000, period: {2, :second}},
        {PhoenixDDOS.IpRateLimitPerRequestPath,
         request_paths: ["/admin"], allowed: 3, period: {1, :minute}}
      ]
      |> put_protections()

      conn = %Plug.Conn{remote_ip: @an_ip}

      start = PhoenixDDOS.Time.now()
      run_ddos(conn, 10_000)

      # ~ 30 ms per 10k
      assert PhoenixDDOS.Time.diff_ms(start) < 100
    end

    test "IpRateLimitPerRequestPath" do
      [
        {PhoenixDDOS.IpRateLimitPerRequestPath,
         request_paths: ["/admin"], allowed: 3, period: {1, :minute}, jail_time: nil}
      ]
      |> put_protections()

      conn = %Plug.Conn{remote_ip: @an_ip, request_path: "/admin"}
      run_ddos(conn, 3)

      conn = %Plug.Conn{remote_ip: @an_ip, request_path: "/user"}
      run_ddos(conn, :never_fail)
    end

    test "IpRateLimitPerRequestPath shared quota along all paths" do
      [
        {PhoenixDDOS.IpRateLimitPerRequestPath,
         request_paths: ["/admin", "/user"], allowed: 3, shared: true, period: {1, :minute}}
      ]
      |> put_protections()

      conn = %Plug.Conn{remote_ip: @an_ip, request_path: "/admin"}
      run_ddos(conn, 3)

      conn = %Plug.Conn{remote_ip: @an_ip, request_path: "/user"}
      run_ddos(conn, 0)
    end
  end


end
