defmodule PhoenixDDoS do
  @moduledoc [__DIR__, "../README.md"]
             |> Path.join()
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(1)

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  if Application.compile_env(:phoenix_ddos, :enabled) == false do
    def call(conn, _opts), do: conn
  else
    def call(%Plug.Conn{} = conn, _opts), do: conn |> PhoenixDDoS.Engine.control()
  end

  @doc """
  Checks a client address against blocklist, safelist, jail and the global IP
  rate limits. Meant for `Phoenix.Socket.connect/3` (socket transports are
  dispatched by the Endpoint before any plug runs).

  Pass the address your app has determined for the client; this function does
  not read `peer_data` itself, since behind a reverse proxy that is the
  proxy's address. Counts as one request for the global IP rules. Path based
  rules are not applied.
  """
  @spec check_socket_ip(:inet.ip_address()) :: :ok | :error
  if Application.compile_env(:phoenix_ddos, :enabled) == false do
    def check_socket_ip(_ip), do: :ok
  else
    def check_socket_ip(ip) when is_tuple(ip), do: PhoenixDDoS.Engine.control_socket(ip)
  end
end
