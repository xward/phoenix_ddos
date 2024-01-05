defmodule PhoenixDDoS.RequestContext do
  @moduledoc false

  # store shared context over process

  def feed(%Plug.Conn{} = conn) do
    Process.put(:phoenix_ddos, %{
      ip: conn.remote_ip |> :inet.ntoa(),
      method: conn.method,
      request_path: conn.request_path,
      route: phoenix_route(conn)
    })
  end

  def get(key), do: Process.get(:phoenix_ddos)[key]

  def pull(:pretty) do
    %{ip: "#{get(:ip)}", method: get(:method), route: get(:route), path: get(:request_path)}
  end

  defp phoenix_route(conn) do
    Application.get_env(:phoenix_ddos, :routers)
    |> Enum.map(fn router ->
      {router, Phoenix.Router.route_info(router, conn.method, conn.request_path, nil)}
    end)
    |> Enum.filter(fn
      {_, %{route: _route}} -> true
      {_, _} -> false
    end)
    |> Enum.map(fn {router, %{route: route}} -> "[#{inspect(router)} #{route}]" end)
    |> case do
      [] -> "unknown route"
      routes -> routes |> Enum.join(" or ")
    end
  end
end
