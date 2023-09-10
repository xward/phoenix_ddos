defmodule PhoenixDDOS do
  @moduledoc """
  Documentation for `PhoenixDDOS`
  """


  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  if Application.compile_env(:phoenix_ddos, :enable) do
    def call(%Plug.Conn{} = conn, _opts) do

      PhoenixDDOS.Engine.control(conn)

      # Jail

    end
  else
    def call(conn, _opts), do: conn
  end

  # returns :cont or :reject
  # defp observe(conn) do
  #   {
  #     false,
  #     %{
  #       ip: conn.remote_ip |> :inet.ntoa(),
  #       request_path: conn.request_path
  #     }
  #   }
  #   |> PhoenixDDOS.IpRateLimit.check()
  #   |> PhoenixDDOS.IpRateLimitPerRequestPath.check()
  #   |> case do
  #     {false, _} -> :cont
  #     {true, _} -> :reject
  #   end
  # end

  def stats do
    # show leaderboard of most spammy ip
    # reject conn count

    IO.puts("stats here")
  end
end
