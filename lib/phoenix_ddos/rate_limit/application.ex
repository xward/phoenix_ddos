defmodule PhoenixDDoS.Application do
  @moduledoc false

  # PhoenixDDoS application, responsible for starting Cachex cache
  use Application

  require Logger

  def start(_type, _args) do
    link = PhoenixDDoS.Supervisor.start_link(%{}, name: PhoenixDDoS.Supervisor)

    PhoenixDDoS.Engine.init()

    protections_count = length(Application.get_env(:phoenix_ddos, :_prots, []))

    if protections_count > 0 do
      Logger.info("PhoenixDDoS ready with #{protections_count} protections.")
    else
      Logger.warning("PhoenixDDoS no protection configured")
    end

    link
  end
end
