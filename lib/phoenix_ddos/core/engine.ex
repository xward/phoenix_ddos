defmodule PhoenixDDoS.Engine do
  @moduledoc false

  require Logger

  alias PhoenixDDoS.TemplateHelper

  # --------------------------------------------------------------
  # main control
  # --------------------------------------------------------------

  # returns conn, or rejected conn
  def control(%Plug.Conn{} = conn) do
    ip = conn.remote_ip |> :inet.ntoa()

    cond do
      ip in Application.get_env(:phoenix_ddos, :blocklist_ips, []) ->
        PhoenixDDoS.Dredd.reject(conn)

      ip in Application.get_env(:phoenix_ddos, :safelist_ips, []) ->
        conn

      PhoenixDDoS.Jail.in_jail?(ip) ->
        PhoenixDDoS.Dredd.reject(conn)

      true ->
        # suggestion perf: upgrade using execution block || custom ETS
        decisions =
          Application.get_env(:phoenix_ddos, :_prots)
          |> Enum.reduce(%{}, fn {module, cfg} = prot, acc ->
            Map.put(acc, module.check(conn, cfg), prot)
          end)

        # map of {a_decision: prot}
        # we can only have one of each
        # a_decision is in [:pass, :block, :jail, :pass]

        cond do
          decisions[:jail] ->
            Logger.warning(
              "PhoenixDDoS: ip[#{ip}] goes to JAIL. From prot #{inspect(decisions[:jail])} with love"
            )

            PhoenixDDoS.Jail.send(ip, decisions[:jail])
            PhoenixDDoS.Dredd.reject(conn)

          decisions[:block] ->
            Logger.warning(
              "PhoenixDDoS: ip[#{ip}] request reject. From prot #{inspect(decisions[:block])} with love"
            )

            PhoenixDDoS.Dredd.reject(conn)

          true ->
            conn
        end
    end
  end

  # --------------------------------------------------------------
  # prepare configuration
  # --------------------------------------------------------------

  def init, do: configure()

  @protections [
    PhoenixDDoS.IpRateLimit,
    PhoenixDDoS.IpRateLimitPerRequestPath
  ]

  def configure do
    Application.put_env(
      :phoenix_ddos,
      :_prots,
      @protections
      |> Enum.map(fn prot ->
        prot
        |> fetch_protection_configurations()
        |> Enum.map(&prepare_prot_cfgs/1)
        |> List.flatten()
      end)
      |> List.flatten()
    )

    # generate PhoenixDDoS.RequestPath
    registers =
      Application.get_env(:phoenix_ddos, :_prots)
      |> Enum.filter(fn {prot, _cfg} ->
        Keyword.has_key?(prot.__info__(:functions), :register_request_path)
      end)
      |> Enum.map(fn {prot, cfg} ->
        cfg
        |> prot.register_request_path()
        |> Enum.map(fn {id, path} ->
          {id, path_to_pattern_match_chunk(path)}
        end)
      end)
      |> List.flatten()

    TemplateHelper.compile(%{registers: registers}, "request_path")
  end

  defp prepare_prot_cfgs({prot, cfg_src}) do
    cfg_src
    |> Map.new()
    |> put_id()
    |> put_sentence()
    |> prot.prepare_config()
    # a prepare_config may split itself in a list of cfg
    # if so, we need to regenerated id for each
    |> case do
      cfgs when is_list(cfgs) -> cfgs |> Enum.map(fn cfg -> {prot, cfg |> put_id()} end)
      cfg -> {prot, cfg}
    end
  end

  defp fetch_protection_configurations(prot) do
    Application.get_env(:phoenix_ddos, :protections)
    |> Enum.filter(fn {p, _} -> p == prot end)
  end

  defp rand_id, do: :crypto.strong_rand_bytes(3) |> Base.encode64()

  defp put_id(cfg), do: cfg |> Map.put(:id, rand_id())

  defp put_sentence(%{jail_time: nil} = cfg), do: cfg |> Map.put(:sentence, :block)
  defp put_sentence(%{jail_time: _} = cfg), do: cfg |> Map.put(:sentence, :jail)

  defp put_sentence(cfg), do: cfg |> Map.put(:jail_time, default_jail_time()) |> put_sentence()

  defp default_jail_time, do: Application.get_env(:phoenix_ddos, :jail_time, {15, :minutes})

  # transform "/admin/:id/dashboard" to "_, "admin", _, "dashboard""
  defp path_to_pattern_match_chunk(path) do
    path
    |> String.split("/")
    |> Enum.map_join(
      ", ",
      fn
        "" -> "_"
        <<":", _rest::binary>> -> "_"
        chunk -> "\"#{chunk}\""
      end
    )
  end
end
