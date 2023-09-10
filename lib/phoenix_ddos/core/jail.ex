defmodule PhoenixDDOS.Jail do
  @moduledoc """
  Ip got caught, go to jail ! Skipping request count
  """

  alias PhoenixDDOS.Time

  def send(ip, {_module, cfg} = _prot) do
    {:ok, _} = Cachex.put(:phoenix_ddos_jail, "suspicious_#{ip}", ttl: :timer.hours(6))

    Cachex.put(:phoenix_ddos_jail, ip, true, ttl: Time.period_to_msec(cfg.jail_time))
  end

  def in_jail?(ip) do
    {:ok, exist} = Cachex.exists?(:phoenix_ddos_jail, ip)
    exist
  end

  def suspicious_ip?(ip) do
    {:ok, exist} = Cachex.exists?(:phoenix_ddos_jail, "suspicious_#{ip}")
    exist
  end

  # you have powerful friend !
  def bail_out(ip) do
    Cachex.del(:phoenix_ddos_jail, ip)
    Cachex.del(:phoenix_ddos_jail, "suspicious_#{ip}")
  end
end
