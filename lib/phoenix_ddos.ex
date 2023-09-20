defmodule PhoenixDDoS do
  @moduledoc [__DIR__, "../README.md"]
             |> Path.join()
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(1)

  @behaviour Plug

  alias PhoenixDDoS.Engine

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  if Application.compile_env(:phoenix_ddos, :enabled) == false do
    def call(conn, _opts), do: conn
  else
    def call(%Plug.Conn{} = conn, _opts), do: PhoenixDDoS.Engine.control(conn)
  end

  @doc """
  Provide in-iex stats
  """
  def stats do
    # show leaderboard of most spammy ip
    # reject conn count

    IO.puts("stats here")
  end
end
