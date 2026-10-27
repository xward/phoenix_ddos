defmodule PhoenixDDoS.RequestContext do
  @moduledoc false

  # store shared context over process

  def feed(%Plug.Conn{} = conn) do
    Process.put(:phoenix_ddos, %{
      ip: PhoenixDDoS.IP.key(conn.remote_ip),
      method: conn.method,
      request_path: conn.request_path
    })
  end

  # socket / non-conn callers: only the client key is known
  def feed_ip(ip_key), do: Process.put(:phoenix_ddos, %{ip: ip_key})

  def get(key), do: Process.get(:phoenix_ddos)[key]

  def pull(:pretty) do
    %{
      ip: "#{get(:ip)}",
      method: get(:method),
      route: phoenix_route(get(:method), get(:request_path)),
      path: get(:request_path)
    }
  end

  # resolved on demand: only telemetry / sentry metadata need it
  # (no request path for sockets, see feed_ip/1)
  defp phoenix_route(_method, nil), do: "unknown route"

  defp phoenix_route(method, request_path) do
    Application.get_env(:phoenix_ddos, :routers)
    |> Enum.map(fn router ->
      {router, Phoenix.Router.route_info(router, method, request_path, nil)}
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
