defmodule PhoenixDDoS.Configure do
  @moduledoc false

  require Logger

  alias PhoenixDDoS.Telemetry
  alias PhoenixDDoS.TemplateHelper

  def init, do: configure()

  @protections [
    PhoenixDDoS.IpRateLimit,
    PhoenixDDoS.IpRateLimitPerRequestPath
  ]

  def configure do
    # create _prot
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

    # convert ip string to charlist
    convert_ip_to_charlist(:safelist_ips)
    convert_ip_to_charlist(:blocklist_ips)

    generate_checkers()

    protections_count = length(Application.get_env(:phoenix_ddos, :_prots, []))

    if protections_count > 0 do
      Logger.info("🛡️ PhoenixDDoS ready with #{protections_count} protections.")
    else
      Logger.warning("🛡️ PhoenixDDoS no protection configured")
    end

    Telemetry.push([:engine, :init], %{protections_count: protections_count}, %{})
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

  # --------------------------------------------------------------
  # Checkers
  # --------------------------------------------------------------

  defp generate_checkers do
    # ip
    ip_registers =
      Application.get_env(:phoenix_ddos, :_prots)
      |> Enum.filter(fn {_prot, cfg} -> is_nil(cfg[:request_paths]) end)

    # request path
    request_path_registers =
      Application.get_env(:phoenix_ddos, :_prots)
      |> Enum.reject(fn {_prot, cfg} -> is_nil(cfg[:request_paths]) end)
      |> Enum.map(fn {prot, cfg} ->
        cfg.request_paths |> Enum.map(fn request_path -> {request_path, prot, cfg} end)
      end)
      |> List.flatten()
      |> Enum.group_by(
        fn {request_path, _prot, _cfg} ->
          path_to_pattern_match_chunk(request_path)
        end,
        fn {_request_path, prot, cfg} -> {prot, cfg} end
      )

    TemplateHelper.compile(
      %{
        ip_registers: ip_registers,
        request_path_registers: request_path_registers
      },
      "engine"
    )
  end

  def convert_ip_to_charlist(key) do
    Application.put_env(
      :phoenix_ddos,
      key,
      Application.get_env(:phoenix_ddos, key, [])
      |> Enum.map(fn
        ip when is_list(ip) -> ip
        ip when is_binary(ip) -> String.to_charlist(ip)
      end)
    )
  end

  # --------------------------------------------------------------
  # Helpers
  # --------------------------------------------------------------

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
