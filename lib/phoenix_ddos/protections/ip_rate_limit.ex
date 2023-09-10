defmodule PhoenixDDOS.IpRateLimit do
  @moduledoc """
  check if an ip ddos
  """

  use PhoenixDDOS.Protection

  # returns in [:pass, :block, :jail]
  def check(conn, cfg) do
    ip = conn.remote_ip |> :inet.ntoa()

    RateLimit.incr_check("ip_#{cfg.id}_#{ip}", cfg.period, cfg.allowed, cfg.sentence)
  end

  def prepare_config(cfg), do: cfg
end
