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
      %{
        id: :phoenix_ddos_store,
        start: {Cachex, :start_link, [:phoenix_ddos_store, []]}
      },
      # only local
      %{
        id: :phoenix_ddos_config,
        start: {Cachex, :start_link, [:phoenix_ddos_config, []]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
