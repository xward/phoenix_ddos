defmodule PhoenixDDoS.IpRateLimitPerRequestPath do
  @moduledoc """
  check if an ip ddos on specific paths
  """

  use PhoenixDDoS.Protection

  # returns in [:pass, :block, :jail]
  def check(conn, cfg) do
    if conn.request_path in cfg.request_paths do
      ip = conn.remote_ip |> :inet.ntoa()

      # ttodo: unify conn.request_path

      key = "ip_#{cfg.id}_#{ip}_r#{conn.request_path}"
      RateLimit.incr_check(key, cfg.period, cfg.allowed, cfg.sentence)
    else
      :pass
    end
  end

  def prepare_config(%{shared: true} = cfg), do: cfg

  def prepare_config(cfg) do
    cfg.request_paths
    |> Enum.map(fn request_path ->
      cfg |> Map.put(:request_paths, [request_path])
    end)
  end
end
