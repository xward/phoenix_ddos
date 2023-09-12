defmodule PhoenixDDoS.IpRateLimitPerRequestPath do
  @moduledoc """
  check if an ip ddos on specific paths
  """

  use PhoenixDDoS.Protection

  # returns in [:pass, :block, :jail]
  @doc false
  def check(conn, cfg) do
    if RequestPath.match?(cfg.id, conn.request_path) do
      ip = conn.remote_ip |> :inet.ntoa()
      key = "ippath_#{cfg.id}_#{ip}"
      RateLimit.incr_check(key, cfg.period, cfg.allowed, cfg.sentence)
    else
      :pass
    end
  end

  @doc false
  def prepare_config(%{shared: true} = cfg), do: cfg

  def prepare_config(cfg) do
    # split in multiple configs
    cfg.request_paths
    |> Enum.map(fn request_path ->
      cfg |> Map.put(:request_paths, [request_path])
    end)
  end

  def register_request_path(cfg) do
    cfg.request_paths
    |> Enum.map(fn request_path -> {cfg.id, request_path} end)
  end
end
