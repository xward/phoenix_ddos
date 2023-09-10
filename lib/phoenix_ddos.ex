defmodule PhoenixDDOS do
  @moduledoc """
  Documentation for `PhoenixDDOS`
  """

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  if Application.compile_env(:phoenix_ddos, :enabled) == false do
    def call(conn, _opts), do: conn
  else
    def call(%Plug.Conn{} = conn, _opts), do: PhoenixDDOS.Engine.control(conn)
  end

  def stats do
    # show leaderboard of most spammy ip
    # reject conn count

    IO.puts("stats here")
  end
end
