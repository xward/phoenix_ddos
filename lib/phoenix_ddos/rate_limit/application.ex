defmodule PhoenixDDOS.Application do
  @moduledoc """
  PhoenixDDOS application, responsible for starting Cachex cache
  """
  use Application

  require Logger

  def start(_type, _args) do
    config = %{}
    link = PhoenixDDOS.Supervisor.start_link(config, name: PhoenixDDOS.Supervisor)

    PhoenixDDOS.Engine.init()

    protections_count = length(Application.get_env(:phoenix_ddos, :prots))
    Logger.info("PhoenixDDOS ready with #{protections_count} protections.")

    link
  end
end
