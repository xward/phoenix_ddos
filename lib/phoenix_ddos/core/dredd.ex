defmodule PhoenixDDoS.Dredd do
  @moduledoc false

  #  Judge, Jury, and Executioner

  import Plug.Conn

  @http_code Application.compile_env(:phoenix_ddos, :http_code_on_reject, 429)
  @raise_on_reject Application.compile_env(:phoenix_ddos, :raise_on_reject, false)

  if @raise_on_reject do
    def reject(conn), do: raise("PhoenixDDoS: too much request")
  else
    def reject(conn), do: conn |> Plug.Conn.send_resp(@http_code, []) |> halt()
  end
end
