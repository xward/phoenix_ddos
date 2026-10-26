defmodule PhoenixDDoS.Jail do
  @moduledoc """
    Ip got caught, go to jail ! Further request will be rejected and won't be included in rate limits

    Ips are tracked by their client key: an IPv4 address, or for IPv6 its
    `ipv6_prefix` network (e.g. "2001:db8::/64"); an IPv4-mapped IPv6 address
    is its IPv4 form. `in_jail?/1`, `suspicious_ip?/1` and `bail_out/1` accept an
    address (string, charlist or tuple), turned into that key, or a key as
    listed by `ips_in_jail/0`.

    iex> PhoenixDDoS.Jail.send(~c"1.2.3.4", Enum.at(Application.get_env( :phoenix_ddos,:_prots),0))
    :ok
    iex> PhoenixDDoS.Jail.ips_in_jail()
    ["1.2.3.4"]
    iex>  PhoenixDDoS.Jail.in_jail?("1.2.3.4")
    true
    iex>  PhoenixDDoS.Jail.in_jail?({1, 2, 3, 4})
    true
    iex>  PhoenixDDoS.Jail.in_jail?("1.2.3.5")
    false
    iex>  PhoenixDDoS.Jail.bail_out("1.2.3.4")
    :ok
    iex>  PhoenixDDoS.Jail.in_jail?("1.2.3.4")
    false
  """

  alias PhoenixDDoS.IP
  alias PhoenixDDoS.Telemetry
  alias PhoenixDDoS.Time

  # `ip` is a client key (PhoenixDDoS.IP.key/1)
  def send(ip, {_module, cfg} = prot) do
    jail_ms = Time.period_to_msec(cfg.jail_time)
    {:ok, _} = Cachex.put(:phoenix_ddos_jail, ip, true, expire: jail_ms)

    {:ok, _} =
      Cachex.put(:phoenix_ddos_suspicious_ips, ip, true, expire: :timer.hours(6))

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
  def in_jail?(ip), do: ip |> IP.lookup_key() |> jailed?()

  @doc false
  # hot path: `key` is already a client key (PhoenixDDoS.IP.key/1)
  def jailed?(key) do
    {:ok, exist} = Cachex.exists?(:phoenix_ddos_jail, key)
    exist
  end

  @doc false
  def suspicious_ip?(ip) do
    {:ok, exist} = Cachex.exists?(:phoenix_ddos_suspicious_ips, IP.lookup_key(ip))
    exist
  end

  @doc "remove ip from jail"
  # you have a powerful friend !
  def bail_out(ip) do
    key = IP.lookup_key(ip)
    Cachex.del(:phoenix_ddos_jail, key)
    Cachex.del(:phoenix_ddos_suspicious_ips, key)
    :ok
  end
end
