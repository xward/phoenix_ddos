defmodule PhoenixDDoS.IpRateLimit do
  @moduledoc """
  check if an ip ddos
  """

  use PhoenixDDoS.Protection

  # returns in [:pass, :block, :jail]
  @doc false
  def check(conn, cfg) do
    ip = conn.remote_ip |> :inet.ntoa()

    RateLimit.incr_check("ip_#{cfg.id}_#{ip}", cfg.period, cfg.allowed, cfg.sentence)
  end

  @doc false
  def prepare_config(cfg), do: cfg
end
