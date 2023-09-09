defmodule PhoenixDDOS.IpRateLimit do
  @moduledoc """
  check if an ip ddos
  """

  use PhoenixDDOS.Checker

  def check({reject, request}) do
    {__MODULE__
     |> Config.get!()
     |> Enum.reduce(reject, fn {id, window_ms, count}, acc ->
       Cache.incr_check("ip_#{id}_#{request.ip}", window_ms, count) || acc
     end), request}
  end

  # from {PhoenixDDOS.IpRateLimit, allowed: 500, period: {1, :minute}}
  # to {"123", 60_000, 500}
  def prepare_config(cfg) do
    {Config.rand_id(), Config.period_to_msec(Keyword.get(cfg, :period)),
     Keyword.get(cfg, :allowed)}
  end
end
