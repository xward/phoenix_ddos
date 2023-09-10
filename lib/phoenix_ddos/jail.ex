defmodule PhoenixDDOS.Jail do
  @moduledoc """
  Ip got caught, go to jail ! Skipping request count
  """

  def send(ip, duration_min \\ nil) do
    duration_min = duration_min || Application.get_env(:phoenix_ddos, :jail_time_minutes)

    {:ok, _} = Cachex.incr(:phoenix_ddos_jail, "suspicious_#{ip}", ttl: :timer.hours(6))

    Cachex.put(:phoenix_ddos_jail, ip, true, ttl: :timer.minutes(duration_min))
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
