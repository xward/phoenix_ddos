defmodule PhoenixDDoS.Monitoring.AlertSentry do
  @moduledoc false

  def alert_goes_to_jail(ip, extra \\ %{}) do
    attrs = [
      "PhoenixDDoS: new ip enter jail",
      extra: %{ip: ip} |> Map.merge(extra)
    ]

    # sentry might not being installed, let use apply/2
    apply(Sentry, :capture_message, attrs)
  end
end
