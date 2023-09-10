defmodule PhoenixDDOS do
  @moduledoc """
  Documentation for `PhoenixDDOS`
  """

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  if Application.compile_env(:phoenix_ddos, :enable) do
    def call(%Plug.Conn{} = conn, _opts), do: PhoenixDDOS.Engine.control(conn)
  else
    def call(conn, _opts), do: conn
  end

  def stats do
    # show leaderboard of most spammy ip
    # reject conn count

    IO.puts("stats here")
  end
end
