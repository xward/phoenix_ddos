defmodule PhoenixDDOS.Engine do
  @moduledoc """
  check and configure
  """

  require Logger

  # --------------------------------------------------------------
  # main control
  # --------------------------------------------------------------

  # returns conn, or rejected conn
  def control(%Plug.Conn{} = conn) do
    ip = conn.remote_ip |> :inet.ntoa()

    if PhoenixDDOS.Jail.in_jail?(ip) do
      PhoenixDDOS.Dredd.reject(conn)
    else
      # suggestion perf: upgrade using cachex execution block
      decisions =
        Application.get_env(:phoenix_ddos, :prots)
        |> Enum.reduce(%{}, fn {module, cfg} = prot, acc ->
          Map.put(acc, module.check(conn, cfg), prot)
        end)

      # map of {a_decision: prot}
      # we can only have one of each
      # a_decision is in [:pass, :block, :jail, :pass]

      cond do
        decisions[:jail] ->
          Logger.warning(
            "PhoenixDDOS: ip[#{ip}] goes to JAIL. From prot #{inspect(decisions[:jail])} with love"
          )

          PhoenixDDOS.Jail.send(ip, decisions[:jail])
          PhoenixDDOS.Dredd.reject(conn)

        decisions[:block] ->
          Logger.warning(
            "PhoenixDDOS: ip[#{ip}] request reject. From prot #{inspect(decisions[:block])} with love"
          )

          PhoenixDDOS.Dredd.reject(conn)

        true ->
          conn
      end
    end
  end

  # --------------------------------------------------------------
  # pre-configuration
  # --------------------------------------------------------------

  def init, do: configure()

  def configure do
    Application.put_env(
      :phoenix_ddos,
      :prots,
      [
        PhoenixDDOS.IpRateLimit,
        PhoenixDDOS.IpRateLimitPerRequestPath
      ]
      |> Enum.map(fn module ->
        module
        |> fetch_protection_configurations()
        |> Enum.map(&prepare_cfgs/1)
        |> List.flatten()
      end)
      |> List.flatten()
    )
  end

  def prepare_cfgs({module, cfg_src}) do
    cfg_src
    |> Map.new()
    |> put_id()
    |> put_sentence()
    |> module.prepare_config()
    # a prepare_config may split itself in a list of cfg
    |> case do
      cfgs when is_list(cfgs) -> cfgs |> Enum.map(fn cfg -> {module, cfg} end)
      cfg -> {module, cfg}
    end
  end

  defp fetch_protection_configurations(module) do
    Application.get_env(:phoenix_ddos, :protections)
    |> Enum.filter(fn {mod, _} -> mod == module end)
  end

  defp rand_id, do: :crypto.strong_rand_bytes(3) |> Base.encode64()

  defp put_id(cfg), do: cfg |> Map.put(:id, rand_id())

  defp put_sentence(%{jail_time: nil} = cfg), do: cfg |> Map.put(:sentence, :block)
  defp put_sentence(%{jail_time: _} = cfg), do: cfg |> Map.put(:sentence, :jail)

  defp put_sentence(cfg),
    do:
      cfg
      |> Map.put(:jail_time, Application.get_env(:phoenix_ddos, :jail_time, {15, :minute}))
      |> put_sentence()
end
