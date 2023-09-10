defmodule PhoenixDDOS.DDOSUtils do
  @moduledoc false

  import ExUnit.Assertions

  def put_protections(protections) do
    Application.put_env(:phoenix_ddos, :protections, protections)
    PhoenixDDOS.Engine.init()
  end

  def run_ddos(conn, :never_fail) do
    1..100
    |> Enum.each(fn _ ->
      conn |> call() |> assert_allowed()
    end)
  end

  def run_ddos(conn, should_fail_after) do
    1..(should_fail_after + 3)
    |> Enum.each(fn
      i when i > should_fail_after ->
        conn |> call() |> assert_rejected()

      _ ->
        conn |> call() |> assert_allowed()
    end)
  end

  def call(conn, opts \\ []) do
    PhoenixDDOS.call(conn, PhoenixDDOS.init(opts))
  end

  def assert_allowed(conn) do
    assert conn.halted == false
    assert conn.status == nil
  end

  def assert_rejected(conn) do
    assert conn.halted
    assert conn.status == Application.get_env(:phoenix_ddos, :http_code_on_reject, 429)
  end

  def assert_in_jail(ip) do
    assert PhoenixDDOS.Jail.in_jail?(ip |> :inet.ntoa())
  end

  def assert_not_in_jail(ip) do
    assert not PhoenixDDOS.Jail.in_jail?(ip |> :inet.ntoa())
  end
end
