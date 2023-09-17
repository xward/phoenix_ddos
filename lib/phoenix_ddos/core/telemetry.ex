defmodule PhoenixDDoS.Telemetry do
  @moduledoc """

  Usage:


  PhoenixDDoS Telemetry events list

    ## Initialization Events

    * `[:phoenix_ddos, :engine, :init]` - when the PhoenixDDoS supervisor is started

      The initialization event contains the following measurements:

      * `:system_time` - The system's time when the negine initalized
      * `:protections_count` - The amount of activated protections




    ## Jail Events


        :telemetry.execute([:phoenix_ddos, :engine, :init], %{protections_count: protections_count})
     :telemetry.execute([:phoenix_ddos, :jail, :new], %{ip: ip})
     [:phoenix_ddos, :jail, :count]
  """

  @doc false
  def push(event, mesurements) do
    :telemetry.execute(event, mesurements |> Map.merge(%{system_time: DateTime.utc_now()})) |> IO.inspect
  end
end
