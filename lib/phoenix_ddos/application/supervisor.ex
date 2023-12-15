defmodule PhoenixDDoS.Supervisor do
  @moduledoc false

  # Top-level Supervisor for the PhoenixDDoS application.

  # Start ETS cache (Cachex)

  use Supervisor

  def start_link(config, opts) do
    Supervisor.start_link(__MODULE__, config, opts)
  end

  def init(_config) do
    children = [
      %{
        id: :phoenix_ddos_store,
        start: {Cachex, :start_link, [:phoenix_ddos_store, []]}
      },
      %{
        id: :phoenix_ddos_jail,
        start: {Cachex, :start_link, [:phoenix_ddos_jail, []]}
      },
      %{
        id: :phoenix_ddos_suspicious_ips,
        start: {Cachex, :start_link, [:phoenix_ddos_suspicious_ips, []]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
