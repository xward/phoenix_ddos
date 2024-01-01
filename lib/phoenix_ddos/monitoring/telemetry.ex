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


  ## Request Events

  * `[:phoenix_ddos, :request, :new]` - request being processed by phoenix ddos engine

    Measurements:

    * `:system_time` - The system's time when the event occured

    Metas:

    * `:ip` - ip source fo request
    * `:method` - http method
    * `:path` - path (ex: /users/12)
    * `:route` - phoenix route (ex: /users/:id)
    * `:decision` - either `:pass` `:block` or `:jail`

  """

  alias PhoenixDDoS.RequestContext

  @doc false
  def push(event, mesurements, metas) do
    :telemetry.execute(
      [:phoenix_ddos] ++ event,
      mesurements |> Map.merge(%{system_time: DateTime.utc_now()}),
      metas
    )
  end

  def push_request_new(decision) do
    push([:request, :new], %{}, Map.put(RequestContext.pull(:pretty), :decision, decision))
  end
end
