defmodule PhoenixDDoS.Telemetry do
  @moduledoc """

  PhoenixDDoS Telemetry events list

    ## Initialization Events

    * `[:phoenix_ddos, :engine, :init]` - when the PhoenixDDoS supervisor is started

      Measurements:

      * `:system_time` - The system's time when the engine initalized
      * `:protections_count` - The amount of activated protections


      note: since this event is fire very soon in a typical phoenix startup, you might not be able to catch it.

    ## Jail Events

    * `[:phoenix_ddos, :jail, :new]` - an ip was sent to jail, being block for a certain amount of time regardeless of quotas

      Measurements:

      * `:system_time` - The system's time when the event occured

      Metas:

      * `:ip` - blocked ip
      * `:protection` - The protection name and configuration that caught this ip

    * `[:phoenix_ddos, :jail, :count]` - when the number of ip in jail increase

      Measurements:

      * `:system_time` - The system's time when the event occured
      * `:total` - The total amount of ip currently in jail



  """

  @doc false
  def push(event, mesurements, metas) do
    :telemetry.execute(
      [:phoenix_ddos] ++ event,
      mesurements |> Map.merge(%{system_time: DateTime.utc_now()}),
      metas
    )
  end
end
