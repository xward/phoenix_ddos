defmodule PhoenixDDOS.Supervisor do
  @moduledoc """
  Top-level Supervisor for the PhoenixDDOS application.

  Start ETS cache (Cachex)
  """

  use Supervisor

  def start_link(config, opts) do
    Supervisor.start_link(__MODULE__, config, opts)
  end

  def init(_config) do
    children = [
      worker(Cachex, [:phoenix_ddos_store, []], id: :phoenix_ddos_store),
      # only local
      worker(Cachex, [:phoenix_ddos_config, []], id: :phoenix_ddos_config)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
