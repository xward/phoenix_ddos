defmodule PhoenixDDOS do
  @moduledoc """
  Documentation for `PhoenixDDOS`.
  """

  alias PhoenixDDDOS.Parser

  import Plug.Conn

  @behaviour Plug

  @impl Plug
  def init(opts) do
    Cachex.start_link(name: :phoenix_ddos)

    opts
  end

  @impl Plug
  def call(conn, _opts) do
    ip = conn.remote_ip |> :inet.ntoa()

    {:ok, new_number} = Cachex.incr(:phoenix_ddos_store, "#{ip}_count")

    if new_number == 1 do
      {:ok, true} = Cachex.expire(:phoenix_ddos_store, "#{ip}_count", :timer.seconds(60))
    end

    if new_number > 10 do
      # IO.puts("boom")
      # 429 Too Many Requests
      conn |> put_status(429) |> halt()
    else
      conn
    end
  end
end
