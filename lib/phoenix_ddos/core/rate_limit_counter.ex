defmodule PhoenixDDoS.RateLimitCounter do
  @moduledoc false

  # centralize rate limit counting and any query stats

  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_state), do: {:ok, %{}}

  # --------------------------------------------------------------
  # API
  # --------------------------------------------------------------

  def batch_check(checkers) do
    GenServer.call(__MODULE__, {:check, checkers})

    # GenServer.call(__MODULE__, {:subscribe, "#livePAR-1rP#{asset_name}"})

    # GenServer.cast(__MODULE__, {:subscribe, "#livePAR-1rP#{asset_name}"})
  end

  # @cachex ttl using process send_after for each ? or shared periodic bam

  # every 15min/1h/6h, print a log with usage (if enabled)

  # --------------------------------------------------------------
  # implementations
  # --------------------------------------------------------------

  # sync
  def handle_call({:check, checkers}, _from, %{rates, ttl} = state) do
    # list of {id, key, period, allowed, decision_if_above}
    {decisions,state} =
    checkers
      |> Enum.reduce(%{}, fn {id, key, period, allowed, decision_if_above} ->
        {rates, ttl} =
          if Keyword.has_key?(rates, key) do
            %{rates: Keyword.update!(rates, key, fn n -> n + 1 end), ttl: ttl}
          else
            # todo: set ttl
            %{
              rates: Keyword.put!(rates, key, 1),
              ttl: ttl
            }
          end
      end)

    decisions = nil
    # build inc, set ttl, return map of decisions with prot id that triggered it

    {:reply, decisions, state}
  end

  # async
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end
end
