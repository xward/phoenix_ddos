defmodule PhoenixDDoS.Monitoring.AlertSentry do
  @moduledoc false

  alias PhoenixDDoS.RequestContext

  @doc false
  def alert_goes_to_jail(prot) do
    attrs = [
      "PhoenixDDoS: new ip enter jail",
      [extra: Map.put(RequestContext.pull(:pretty), :protection, inspect(prot))]
    ]

    # sentry might not being installed, let use apply/2
    apply(Sentry, :capture_message, attrs)
  end
end
