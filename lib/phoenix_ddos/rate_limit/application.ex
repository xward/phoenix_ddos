defmodule PhoenixDDoS.Application do
  @moduledoc false

  # PhoenixDDoS application, responsible for starting Cachex cache
  use Application

  require Logger

  def start(_type, _args) do
    PhoenixDDoS.Engine.init()
    PhoenixDDoS.Supervisor.start_link(%{}, name: PhoenixDDoS.Supervisor)
  end
end
