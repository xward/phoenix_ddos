defmodule PhoenixDDOS.Dredd do
  @moduledoc """
  Judge, Jury, and Executioner
  """
  import Plug.Conn

  def reject(%Plug.Conn{} = conn) do
    cond do
      config(:raise_on_reject, false) ->
        raise "PhoenixDDOS: too much request"

      true ->
        conn |> put_status(config(:http_code_on_reject, 429)) |> halt()
    end
  end

  defp config(key, default) do
    Application.get_env(:phoenix_ddos, key, default)
  end
end
