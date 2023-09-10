defmodule PhoenixDDOS.Engine do
  @moduledoc """
  Generate and compile a module EngineImpl on the fly.
  Reason: small final code size/complexity and extreme performance (x30 faster than an ets cache)
  This is unortodox? yes. Don't try this at home.
  """

  # --------------------------------------------------------------
  # main control
  # --------------------------------------------------------------

  # returns conn, or rejected conn
  def control(%Plug.Conn{} = conn) do
    # PhoenixDDOS.EngineImpl.control(conn)
  end

  # --------------------------------------------------------------
  # Code generation
  # --------------------------------------------------------------

  def init, do: generate()

  def generate do
      prot =[
        PhoenixDDOS.IpRateLimit,
        PhoenixDDOS.IpRateLimitPerRequestPath
      ]
      |> Keyword.new(fn module ->
        {module, # convert to nicer atom plz
         module
         |> fetch_protection_configurations()
         |> Enum.map(&prepare_config/1)
         |> List.flatten()}
      end)

      Application.put_env(:phoenix_ddos, :prot, prot)

  end

  defp prepare_config({PhoenixDDOS.IpRateLimit, cfg}) do
    %{id: rand_id()} |> put_rate_limit(cfg)
  end

  defp prepare_config({PhoenixDDOS.IpRateLimitPerRequestPath, cfg}) do
    if Keyword.get(cfg, :shared) == true do
      %{id: rand_id(), paths: Keyword.get(cfg, :request_paths)} |> put_rate_limit(cfg)
    else
      Keyword.get(cfg, :request_paths)
      |> Enum.map(fn path ->
        %{id: rand_id(), paths: [path]} |> put_rate_limit(cfg)
      end)
    end
  end

  defp put_rate_limit(map, cfg) do
    map
    |> Map.merge(%{
      period_ms: period_to_msec(Keyword.get(cfg, :period)),
      allowed: Keyword.get(cfg, :allowed)
    })
  end

  defp fetch_protection_configurations(module) do
    Application.get_env(:phoenix_ddos, :protections)
    |> Enum.filter(fn {mod, _} -> mod == module end)
  end

  defp rand_id do
    :crypto.strong_rand_bytes(3) |> Base.encode64()
  end

  defp period_to_msec({n, :second}), do: n * 1_000
  defp period_to_msec({n, :minute}), do: n * 60_000
  defp period_to_msec({n, :hour}), do: n * 3_600_000
  defp period_to_msec({n, :day}), do: n * 24 * 3_600_000
  defp period_to_msec(period), do: raise("Invalid configuration period #{period}")

  # defp preview_compile(context) do
  #   "lib/phoenix_ddos/engine/engine_impl.eex"
  #   |> EEx.eval_file(context)
  # end

  # defp compile(context) do
  #   "lib/phoenix_ddos/engine/engine_impl.eex"
  #   |> EEx.eval_file(context)
  #   |> Code.compile_string()
  # end
end

# upgrade using execution block
