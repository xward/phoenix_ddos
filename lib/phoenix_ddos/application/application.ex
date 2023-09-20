defmodule PhoenixDDoS.Application do
  @moduledoc false

  # PhoenixDDoS application, responsible for starting Cachex cache
  use Application

  def start(_type, _args) do
    PhoenixDDoS.Configure.init()
    PhoenixDDoS.Supervisor.start_link(%{}, name: PhoenixDDoS.Supervisor)
  end
end
