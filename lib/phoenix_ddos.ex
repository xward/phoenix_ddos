defmodule PhoenixDDOS do
  @moduledoc """
  Documentation for `PhoenixDDOS`.
  """

  import Plug.Conn
  alias PhoenixDDOS.IpCheck

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    with :cont <- IpCheck.check(conn) do
      conn
    else
      _ -> reject(conn)
    end
  end

  defp reject(%Plug.Conn{} = conn) do
    cond do
      config(:raise_on_reject, false) ->
        raise "PhoenixDDOS: too much request"

      true ->
        conn |> put_status(config(:http_code_on_reject, 429)) |> halt()
    end
  end

  def stats do
    # show leaderboard of most spammy ip
    # reject conn count

    IO.puts("stats here")
  end

  defp config(key, default \\ nil) do
    Application.get_env(:phoenix_ddos, key, default)
  end
end
