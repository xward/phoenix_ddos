defmodule PhoenixDDOSTest do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest PhoenixDDOS

  def call(conn, opts \\ []) do
    PhoenixDDOS.call(conn, PhoenixDDOS.init(opts))
  end

  describe "call/2" do
    test "no headers" do
      peer = {86, 75, 30, 9}
      head = []
      conn = %Plug.Conn{remote_ip: peer, req_headers: head}
      assert call(conn).remote_ip == peer
      assert Logger.metadata()[:remote_ip] == "86.75.30.9"
    end
  end
end
