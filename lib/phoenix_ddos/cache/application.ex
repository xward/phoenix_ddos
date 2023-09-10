defmodule PhoenixDDOS.Application do
  @moduledoc """
  PhoenixDDOS application, responsible for starting Cachex cache
  """
  use Application

  def start(_type, _args) do
    config = %{}
    link = PhoenixDDOS.Supervisor.start_link(config, name: PhoenixDDOS.Supervisor)

    PhoenixDDOS.Engine.init()
    link
  end
end
