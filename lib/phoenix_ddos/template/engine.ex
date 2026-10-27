defmodule PhoenixDDoS.Engine do
  @moduledoc false

  # compile-time stub: replaced at application start by the engine compiled at
  # runtime from engine.eex (PhoenixDDoS.Configure). Until then (app not
  # started) everything passes, fail-open.
  def control(conn), do: conn
  def control_socket(_address), do: :ok
end
