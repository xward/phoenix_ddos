defmodule PhoenixDDoS.Engine do
  @moduledoc false
  def control(conn), do: conn

  # compile-time stub, same contract as the generated engine: it is replaced at
  # application start by the engine compiled at runtime from engine.eex
  # (PhoenixDDoS.Configure). Until then (app not started) it returns :pass,
  # fail-open like control/1 above.
  @spec decide(charlist, [String.t()]) :: :pass | :block | :jail
  # opaque on purpose: dialyzer must not narrow callers to :pass
  def decide(_ip, _segments), do: Application.get_env(:phoenix_ddos, :__engine_stub__, :pass)
end
