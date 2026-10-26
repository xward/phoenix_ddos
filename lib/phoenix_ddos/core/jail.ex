defmodule PhoenixDDoS.Jail do
  @moduledoc """
    Ip got caught, go to jail ! Further request will be rejected and won't be included in rate limits

    The jail lives in memory and is the only thing consulted on the request path. Configure a
    `PhoenixDDoS.Store` to also keep the bans in your database: they then survive a restart.

    iex> PhoenixDDoS.Jail.send(~c"1.2.3.4", Enum.at(Application.get_env( :phoenix_ddos,:_prots),0))
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

  alias PhoenixDDoS.Ban
  alias PhoenixDDoS.Store.Server
  alias PhoenixDDoS.Telemetry
  alias PhoenixDDoS.Time

  @doc """
  Send an ip to jail, caught by the protection `prot` (`{module, cfg}`).

  `conn` is the request that got it caught, given to the store (see `PhoenixDDoS.Store`), `nil`
  when there is none.
  """
  def send(ip, prot, conn \\ nil)

  def send(ip, {_module, cfg} = prot, conn) do
    ip = to_charlist(ip)
    ban = Ban.new(ip, prot)

    {:ok, _} = Cachex.put(:phoenix_ddos_jail, ip, ban, ttl: Time.period_to_msec(cfg.jail_time))
    {:ok, _} = Cachex.put(:phoenix_ddos_suspicious_ips, ip, true, ttl: :timer.hours(6))
    Server.insert_ban(ban, conn)
    Telemetry.push([:jail, :new], %{}, %{ip: ip, protection: prot, ban: ban})

    {:ok, total} = Cachex.size(:phoenix_ddos_jail)
    Telemetry.push([:jail, :count], %{total: total}, %{})
  end

  @doc "list all ips in jail"
  def ips_in_jail do
    {:ok, keys} = Cachex.keys(:phoenix_ddos_jail)
    keys |> Enum.map(&to_string/1)
  end

  @doc "list all bans in jail"
  @spec bans() :: [Ban.t()]
  def bans do
    {:ok, keys} = Cachex.keys(:phoenix_ddos_jail)
    keys |> Enum.map(&get/1) |> Enum.reject(&is_nil/1)
  end

  @doc "the ban of an ip in jail, nil when it is not"
  @spec get(charlist() | String.t()) :: Ban.t() | nil
  def get(ip) when is_binary(ip), do: ip |> String.to_charlist() |> get()

  def get(ip) do
    {:ok, ban} = Cachex.get(:phoenix_ddos_jail, ip)
    ban
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
    Server.release_ban(to_string(ip), Time.now())
    :ok
  end

  @doc false
  # used by the store server at boot: back to jail, no write back to the store
  def put_from_store(%Ban{} = ban, now) do
    case Ban.remaining_ms(ban, now) do
      0 ->
        :skip

      ttl ->
        {:ok, _} = Cachex.put(:phoenix_ddos_jail, String.to_charlist(ban.ip), ban, ttl: ttl)
        :ok
    end
  end
end
