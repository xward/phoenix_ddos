defmodule PhoenixDDoS.Jail do
  @moduledoc """
    Ip got caught, go to jail ! Further request will be rejected and won't be included in rate limits

    iex> PhoenixDDoS.Jail.send('1.2.3.4', Enum.at(Application.get_env( :phoenix_ddos,:_prots),0))
    :ok
    iex> PhoenixDDoS.Jail.ips_in_jail()
    ["1.2.3.4"]
    iex>  PhoenixDDoS.Jail.in_jail?("1.2.3.4")
    true
    iex>  PhoenixDDoS.Jail.in_jail?("1.2.3.5")
    false
    iex>  PhoenixDDoS.Jail.bail_out("1.2.3.4")
    :ok
    iex>  PhoenixDDoS.Jail.in_jail?("1.2.3.4")
    false
  """

  alias PhoenixDDoS.Telemetry
  alias PhoenixDDoS.Time

  def send(ip, {_module, cfg} = prot) do
    {:ok, _} = Cachex.put(:phoenix_ddos_jail, ip, true, ttl: Time.period_to_msec(cfg.jail_time))
    {:ok, _} = Cachex.put(:phoenix_ddos_suspicious_ips, ip, true, ttl: :timer.hours(6))
    Telemetry.push([:jail, :new], %{}, %{ip: ip, protection: prot})

    {:ok, total} = Cachex.size(:phoenix_ddos_jail)
    Telemetry.push([:jail, :count], %{total: total}, %{})
  end

  @doc "list all ips in jail"
  def ips_in_jail do
    {:ok, keys} = Cachex.keys(:phoenix_ddos_jail)
    keys |> Enum.map(&to_string/1)
  end

  @doc "check if an ip is in jail"
  def in_jail?(ip) when is_binary(ip), do: ip |> String.to_charlist() |> in_jail?()

  def in_jail?(ip) do
    {:ok, exist} = Cachex.exists?(:phoenix_ddos_jail, ip)
    exist
  end

  @doc false
  def suspicious_ip?(ip) when is_binary(ip), do: ip |> String.to_charlist() |> in_jail?()

  def suspicious_ip?(ip) do
    {:ok, exist} = Cachex.exists?(:phoenix_ddos_suspicious_ips, ip)
    exist
  end

  @doc "remove ip from jail"
  # you have a powerful friend !
  def bail_out(ip) when is_binary(ip), do: ip |> String.to_charlist() |> bail_out()

  def bail_out(ip) do
    Cachex.del(:phoenix_ddos_jail, ip)
    Cachex.del(:phoenix_ddos_suspicious_ips, ip)
    :ok
  end
end
