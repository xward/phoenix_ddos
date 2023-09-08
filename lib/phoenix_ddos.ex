defmodule PhoenixDDOS do
  @moduledoc """
  Documentation for `PhoenixDDOS`
  """

  alias PhoenixDDOS.IpCheck
  alias PhoenixDDOS.Dredd

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    with :cont <- IpCheck.check(conn) do
      conn
    else
      _ -> Dredd.reject(conn)
    end
  end

  def stats do
    # show leaderboard of most spammy ip
    # reject conn count

    IO.puts("stats here")
  end
end
