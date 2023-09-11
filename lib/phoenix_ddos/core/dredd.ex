defmodule PhoenixDDoS.Dredd do
  @moduledoc false

  #  Judge, Jury, and Executioner

  import Plug.Conn

  def reject(%Plug.Conn{} = conn) do
    if config(:raise_on_reject, false) do
      raise "PhoenixDDoS: too much request"
    else
      conn |> put_status(config(:http_code_on_reject, 429)) |> halt()
    end
  end

  defp config(key, default) do
    Application.get_env(:phoenix_ddos, key, default)
  end
end
