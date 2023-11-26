defmodule PhoenixDDoS.Observer do
  @moduledoc """
  Print periodic log with stats to get an idea of traffic to configure protections accordingly.

  # stats 1 min, 5 min, 15 min, 1h
  # periodic prints
  # unit tests (run calls, test peak_print)
  # dializer


  # using genserver for counting 5 min+, use cachex for live incr, genserver for stats agregations
  # https://hexdocs.pm/cachex/Cachex.html#stream/3
  # https://hexdocs.pm/cachex/Cachex.html#invoke/4
  # Cachex.clear() size()
  """

  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_state) do
    :telemetry.attach(
      "observer_request",
      [:phoenix_ddos, :request, :new],
      &__MODULE__.new_request_event/4,
      nil
    )

    # send after 15min, 1h, send after 6h

    {:ok, %{ips: %{}, paths: %{}}}
  end

  # --------------------------------------------------------------
  # API
  # --------------------------------------------------------------

  @doc """
  return map version of current stacked stats without flushing them
  """
  def peak_stats do
    GenServer.call(__MODULE__, :peak_stats)
  end

  @doc """
  print current stacked stats without flushing them
  """
  def peak_print do
    stats = peak_stats()
    # start with PObs
    # peak_stats()
    # |> print()
  end

  # --------------------------------------------------------------
  # implementations
  # --------------------------------------------------------------

  def handle_call(:peak_stats, %{ips: ips, paths: paths}) do
    {:ok, %{}}
  end

  @store :phoenix_ddos_observer

  @doc false
  def new_request_event(_event, _measurement, %{ip: ip, method: method, path: path}, _config) do
    path = phoenix_path(method, path)

    Cachex.execute!(@store, fn _ ->
      ["ip_#{ip}", "path_#{path}"] |> Enum.each(fn key -> Cachex.incr(@store, key) end)
    end)

    # GenServer.cast(__MODULE__, {:new_request_event, measurement, meta})
  end

  @doc false
  # def handle_cast(
  #       {:new_request_event, measurement, %{ip: ip, method: method, path: path} = _meta},
  #       %{ips: ips, paths: paths}
  #     ) do
  #   {:noreply,
  #    %{
  #      ips: Map.update(ips, ip, 1, &incr/1),
  #      paths: Map.update(paths, phoenix_path(method, path), 1, &incr/1)
  #    }}
  # end

  @doc false
  # defp incr(c), do: c + 1

  @doc false
  defp phoenix_path(method, path) do
    Application.get_env(:phoenix_ddos, :router)
    |> Phoenix.Router.route_info(method, path, nil)
    |> case do
      :error -> "#{method} unknown route"
      %{route: route} -> "#{method} #{route}"
    end
  end

  @doc false
  defp print(state) do
  end
end
