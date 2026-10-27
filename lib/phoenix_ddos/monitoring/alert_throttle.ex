defmodule PhoenixDDoS.Monitoring.AlertThrottle do
  @moduledoc false

  # Caps jail alerts (log + sentry) per wall-clock minute so an attack from many
  # IPs can't flood logs or Sentry. Telemetry is never capped.
  # The counter lives in its own unbounded cache (one key per minute, expiring):
  # in the size-bounded :phoenix_ddos_store, eviction under load could drop it
  # and reset the cap.

  require Logger

  @store :phoenix_ddos_alerts
  @window_ms 60_000
  @default_max 10

  @doc "Returns true when an alert may be emitted now, false when it is suppressed."
  def allow? do
    max = Application.get_env(:phoenix_ddos, :max_jail_alerts_per_minute, @default_max)
    now = System.os_time(:millisecond)
    key = "alerts_#{div(now, @window_ms)}"

    {:ok, n} = Cachex.incr(@store, key)
    if n == 1, do: Cachex.expire(@store, key, 2 * @window_ms)

    if n == max + 1 do
      Logger.warning(
        "🛡️ PhoenixDDoS: jail alerts suppressed (more than #{max} per minute), see telemetry for the full count"
      )
    end

    n <= max
  end
end
