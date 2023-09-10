defmodule PhoenixDDOSTest do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest PhoenixDDOS

  @an_ip {1, 2, 3, 4}

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
      |> configure_protections()

      conn = %Plug.Conn{remote_ip: @an_ip}
      run_ddos(conn, 10)

      :timer.sleep(3000)
      # still blocked, even if we waited more than period
      run_ddos(conn, 0)
    end

    test "IpRateLimit thottle" do
      [
        {PhoenixDDOS.IpRateLimit, allowed: 10, period: {2, :second}, jail_time: nil}
      ]
      |> configure_protections()

      conn = %Plug.Conn{remote_ip: @an_ip}
      run_ddos(conn, 10)

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
      |> configure_protections()

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
      |> configure_protections()

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
      |> configure_protections()

      conn = %Plug.Conn{remote_ip: @an_ip, request_path: "/admin"}
      run_ddos(conn, 3)

      conn = %Plug.Conn{remote_ip: @an_ip, request_path: "/user"}
      run_ddos(conn, 0)
    end
  end

  # ------------------------------------------------------------------
  # utils
  # ------------------------------------------------------------------

  defp configure_protections(protections) do
    Application.put_env(:phoenix_ddos, :protections, protections)
    PhoenixDDOS.Engine.init()
  end

  defp run_ddos(conn, :never_fail) do
    1..100
    |> Enum.each(fn _ ->
      conn |> call() |> assert_allowed()
    end)
  end

  defp run_ddos(conn, should_fail_after) do
    1..(should_fail_after + 3)
    |> Enum.each(fn
      i when i > should_fail_after ->
        conn |> call() |> assert_rejected()

      _ ->
        conn |> call() |> assert_allowed()
    end)
  end

  defp call(conn, opts \\ []) do
    PhoenixDDOS.call(conn, PhoenixDDOS.init(opts))
  end

  defp assert_allowed(conn) do
    assert conn.halted == false
    assert conn.status == nil
  end

  defp assert_rejected(conn) do
    assert conn.halted
    assert conn.status == Application.get_env(:phoenix_ddos, :http_code_on_reject, 429)
  end
end
