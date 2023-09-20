defmodule PhoenixDDoS.DDOSUtils do
  @moduledoc false

  import ExUnit.Assertions

  def put_protections(protections) do
    Application.put_env(:phoenix_ddos, :protections, protections)
    PhoenixDDoS.Configure.init()
  end

  def flush_protections, do: [] |> put_protections()

  def run_ddos(conn, :always_fail) do
    1..100
    |> Enum.each(fn _ -> conn |> call() |> assert_rejected() end)
  end

  def run_ddos(conn, :never_fail) do
    1..100
    |> Enum.each(fn _ -> conn |> call() |> assert_allowed() end)
  end

  def run_ddos(conn, %{assert_fail_after_request: fail_after}) do
    1..(fail_after + 3)
    |> Enum.each(fn
      i when i > fail_after ->
        conn |> call() |> assert_rejected()

      _ ->
        conn |> call() |> assert_allowed()
    end)
  end

  def run_ddos(conn, opts), do: run_ddos(conn, Map.new(opts))

  def call(conn, opts \\ []) do
    PhoenixDDoS.call(conn, PhoenixDDoS.init(opts))
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
    assert PhoenixDDoS.Jail.in_jail?(ip |> :inet.ntoa())
  end

  def assert_not_in_jail(ip) do
    assert not PhoenixDDoS.Jail.in_jail?(ip |> :inet.ntoa())
  end
end
