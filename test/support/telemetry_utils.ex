defmodule PhoenixDDoS.Test.TelemetryUtils do
  @moduledoc false

  def handle_telemetry_event(name, measurements, metadata, _config) do
    send(self(), {:telemetry_event, name, measurements, metadata})
  end
end
