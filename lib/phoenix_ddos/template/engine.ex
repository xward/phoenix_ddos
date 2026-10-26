defmodule PhoenixDDoS.Engine do
  @moduledoc false
  def control(conn), do: conn

  # compile-time stub, same contract as the generated engine
  @spec decide(charlist, [String.t()]) :: :pass | :block | :jail
  # opaque on purpose: dialyzer must not narrow callers to :pass
  def decide(_ip, _segments), do: Application.get_env(:phoenix_ddos, :__engine_stub__, :pass)
end
