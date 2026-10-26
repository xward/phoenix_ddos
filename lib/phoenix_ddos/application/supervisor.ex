defmodule PhoenixDDoS.Supervisor do
  @moduledoc false

  # Top-level Supervisor for the PhoenixDDoS application.

  # Start ETS cache (Cachex)

  use Supervisor

  import Cachex.Spec

  def start_link(config, opts) do
    Supervisor.start_link(__MODULE__, config, opts)
  end

  def init(_config) do
    max_entries = Application.get_env(:phoenix_ddos, :max_entries, 1_000_000)
    max_jail_entries = Application.get_env(:phoenix_ddos, :max_jail_entries, 100_000)

    children = [
      %{
        id: :phoenix_ddos_store,
        start: {Cachex, :start_link, [:phoenix_ddos_store, [hooks: [limit(max_entries)]]]}
      },
      %{
        id: :phoenix_ddos_jail,
        start: {Cachex, :start_link, [:phoenix_ddos_jail, [hooks: [limit(max_jail_entries)]]]}
      },
      %{
        id: :phoenix_ddos_suspicious_ips,
        start:
          {Cachex, :start_link,
           [:phoenix_ddos_suspicious_ips, [hooks: [limit(max_jail_entries)]]]}
      },
      # jail alert counter (PhoenixDDoS.Monitoring.AlertThrottle): a couple of
      # expiring keys, unbounded so that eviction never resets the cap
      %{
        id: :phoenix_ddos_alerts,
        start: {Cachex, :start_link, [:phoenix_ddos_alerts, []]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # Cachex 4.0.3 docs say 1s but code defaults to 3s: set it explicitly.
  defp limit(max), do: hook(module: Cachex.Limit.Scheduled, args: {max, [], [frequency: 1_000]})
end
