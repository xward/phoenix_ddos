defmodule PhoenixDDDOS.Parser do
  @moduledoc """
  Parser utils
  """

  def parse_conn(%Plug.Conn{} = conn) do
    %{
      ip: conn.remote_ip |> :inet.ntoa()
    }
  end
end
