defmodule PhoenixDDOSTest do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest PhoenixDDOS

  describe "call/2" do
    test "ddos from same ip" do
      peer = {86, 75, 30, 9}
      head = []
      conn = %Plug.Conn{remote_ip: peer, req_headers: head}

      1..12
      |> Enum.each(fn i ->
        if i > 10 do
          conn |> call() |> assert_rejected()
        else
          conn |> call() |> assert_allowed()
        end
      end)
    end
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
    assert conn.status == 429
  end
end
