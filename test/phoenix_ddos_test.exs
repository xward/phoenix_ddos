defmodule PhoenixDDOSTest do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest PhoenixDDOS

  describe "call/2" do
    test "IpRateLimit with restore" do
      configure_protections([{PhoenixDDOS.IpRateLimit, allowed: 10, period: {2, :second}}])

      peer = {86, 75, 30, 9}
      conn = %Plug.Conn{remote_ip: peer}
      run_ddos(conn, 10)

      :timer.sleep(3000)
      run_ddos(conn, 10)
    end

    test "IpRateLimitPerRequestPath" do
      configure_protections([
        {PhoenixDDOS.IpRateLimitPerRequestPath,
         request_paths: ["/admin"], allowed: 3, period: {1, :minute}}
      ])

      peer = {86, 75, 30, 9}
      conn = %Plug.Conn{remote_ip: peer, request_path: "/admin"}
      run_ddos(conn, 3)

      conn = %Plug.Conn{remote_ip: peer, request_path: "/user"}
      run_ddos(conn, :never)
    end

    test "IpRateLimitPerRequestPath shared quota along all paths" do
      configure_protections([
        {PhoenixDDOS.IpRateLimitPerRequestPath,
         request_paths: ["/admin", "/user"], allowed: 3, shared: true, period: {1, :minute}}
      ])

      peer = {86, 75, 30, 9}
      conn = %Plug.Conn{remote_ip: peer, request_path: "/admin"}
      run_ddos(conn, 3)

      conn = %Plug.Conn{remote_ip: peer, request_path: "/user"}
      run_ddos(conn, 0)
    end
  end

  # ------------------------------------------------------------------
  # utils
  # ------------------------------------------------------------------

  defp configure_protections(protections) do
    Application.put_env(:phoenix_ddos, :protections, protections)
    PhoenixDDOS.Config.init()
  end

  defp run_ddos(conn, :never) do
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
