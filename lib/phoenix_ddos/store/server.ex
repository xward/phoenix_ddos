defmodule PhoenixDDoS.Store.Server do
  @moduledoc """
  The one process talking to the configured `PhoenixDDoS.Store`. Started only when a store is
  configured.

  * boot: `c:PhoenixDDoS.Store.init/1`, then the active bans of the store go back to jail. A
    store that is down at boot (database not ready...) is retried every `:store_retry_interval`
    (default `{5, :seconds}`), the writes made meanwhile wait for it
  * writes: bans and bail outs are casted, never blocking a request, and written in order
  * errors: logged, `[:phoenix_ddos, :store, :error]` is emitted, the jail is never affected
  """

  use GenServer

  alias PhoenixDDoS.Ban
  alias PhoenixDDoS.Jail
  alias PhoenixDDoS.Telemetry
  alias PhoenixDDoS.Time

  require Logger

  # writes kept while the store is down at boot
  @pending_limit 1_000

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc false
  def insert_ban(%Ban{} = ban, conn), do: cast({:insert_ban, ban, conn})

  @doc false
  def release_ban(ip, released_at), do: cast({:release_ban, ip, released_at})

  @doc "wait for every pending write to be done. Mostly for tests and consoles."
  def flush, do: GenServer.call(__MODULE__, :flush)

  # no store configured, no server: nothing to do
  defp cast(message) do
    case Process.whereis(__MODULE__) do
      nil -> :ok
      pid -> GenServer.cast(pid, message)
    end
  end

  # --------------------------------------------------------------
  # GenServer
  # --------------------------------------------------------------

  @impl true
  def init(_opts), do: {:ok, %{store: nil, pending: []}, {:continue, :init_store}}

  @impl true
  def handle_continue(:init_store, state), do: {:noreply, init_store(state)}

  @impl true
  def handle_info(:init_store, state), do: {:noreply, init_store(state)}

  @impl true
  def handle_cast(message, %{store: nil, pending: pending} = state) do
    {:noreply, %{state | pending: Enum.take([message | pending], @pending_limit)}}
  end

  def handle_cast(message, state) do
    write(state.store, message)
    {:noreply, state}
  end

  @impl true
  def handle_call(:flush, _from, state), do: {:reply, :ok, state}

  # --------------------------------------------------------------
  # Store calls
  # --------------------------------------------------------------

  defp init_store(state) do
    {module, opts} = config()

    case run(:init, fn -> module.init(opts) end) do
      {:ok, store_state} ->
        store = {module, store_state}
        warm_up(store)
        state.pending |> Enum.reverse() |> Enum.each(&write(store, &1))
        %{state | store: store, pending: []}

      _error ->
        Process.send_after(self(), :init_store, retry_interval())
        state
    end
  end

  defp warm_up({module, store_state}) do
    now = Time.now()

    case run(:active_bans, fn -> module.active_bans(store_state, now) end) do
      {:ok, bans} ->
        Enum.each(bans, &Jail.put_from_store(&1, now))
        Logger.info("🛡️ PhoenixDDoS: #{length(bans)} bans back in jail from #{inspect(module)}")

      _error ->
        :ok
    end
  end

  defp write({module, store_state}, {:insert_ban, ban, conn}),
    do: run(:insert_ban, fn -> module.insert_ban(store_state, ban, conn) end)

  defp write({module, store_state}, {:release_ban, ip, released_at}),
    do: run(:release_ban, fn -> module.release_ban(store_state, ip, released_at) end)

  # a store never takes the server down: errors and exceptions are logged and emitted
  defp run(operation, fun) do
    case fun.() do
      {:error, reason} -> store_error(operation, reason)
      result -> result
    end
  rescue
    e -> store_error(operation, e)
  catch
    :exit, reason -> store_error(operation, reason)
  end

  defp store_error(operation, reason) do
    Logger.error("🛡️ PhoenixDDoS: store #{operation} failed: #{inspect(reason)}")
    Telemetry.push([:store, :error], %{}, %{operation: operation, reason: reason})
    {:error, reason}
  end

  defp config do
    case Application.get_env(:phoenix_ddos, :store) do
      {module, opts} when is_atom(module) and is_list(opts) ->
        {module, opts}

      module when is_atom(module) and not is_nil(module) ->
        {module, []}

      other ->
        raise ArgumentError,
              "PhoenixDDoS: invalid store #{inspect(other)}, expected a module or {module, opts}"
    end
  end

  defp retry_interval do
    case Application.get_env(:phoenix_ddos, :store_retry_interval, {5, :seconds}) do
      ms when is_integer(ms) -> ms
      period -> Time.period_to_msec(period)
    end
  end
end
