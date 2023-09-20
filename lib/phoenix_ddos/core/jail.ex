defmodule PhoenixDDoS.Jail do
  @moduledoc false

  # Ip got caught, go to jail ! Skipping request count

  alias PhoenixDDoS.Monitoring.AlertSentry
  alias PhoenixDDoS.Telemetry
  alias PhoenixDDoS.Time

  @sentry Application.compile_env(:phoenix_ddos, :on_jail_alert_to_sentry)

  def send(ip, {_module, cfg} = prot) do
    Cachex.put(:phoenix_ddos_jail, ip, true, ttl: Time.period_to_msec(cfg.jail_time))

    {:ok, _} = Cachex.put(:phoenix_ddos_jail, "suspicious_#{ip}", ttl: :timer.hours(6))

    Telemetry.push([:jail, :new], %{}, %{ip: ip, protection: prot})

    if @sentry, do: AlertSentry.alert_goes_to_jail(ip, %{protection: prot})

    {:ok, total} = Cachex.size(:phoenix_ddos_jail)
    Telemetry.push([:jail, :count], %{total: total}, %{})
  end

  def in_jail?(ip) do
    {:ok, exist} = Cachex.exists?(:phoenix_ddos_jail, ip)
    exist
  end

  def suspicious_ip?(ip) do
    {:ok, exist} = Cachex.exists?(:phoenix_ddos_jail, "suspicious_#{ip}")
    exist
  end

  # you have a powerful friend !
  def bail_out(ip) do
    Cachex.del(:phoenix_ddos_jail, ip)
    Cachex.del(:phoenix_ddos_jail, "suspicious_#{ip}")
  end
end
