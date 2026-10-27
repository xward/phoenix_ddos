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

  # apps reconfigure at runtime, possibly from several processes at once (e.g.
  # telemetry handlers banning ips): one at a time, as the engine modules can't
  # be defined twice concurrently
  def configure, do: :global.trans({__MODULE__, self()}, &do_configure/0, [node()])

  defp do_configure do
    # validate some configuration provided by user
    validate!()

    Application.put_env(
      :phoenix_ddos,
      :routers,
      phoenix_routers()
    )

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
      # id from the config, not random: counters (keyed by id) survive a
      # reconfigure, a request in flight keeps valid ids, and a changed
      # protection starts fresh. A protection listed twice would share its id.
      |> Enum.uniq()
      |> Enum.map(fn {prot, cfg} ->
        {prot, Map.put(cfg, :id, "#{:erlang.phash2({prot, cfg}, 4_294_967_296)}")}
      end)
    )

    # ip entries become client keys (PhoenixDDoS.IP.key/1), in place: a key is
    # a valid entry, so init can run again
    put_ip_keys(:safelist_ips)
    put_ip_keys(:blocklist_ips)

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
    |> put_sentence()
    |> prot.prepare_config()
    # a prepare_config may split itself in a list of cfg
    |> case do
      cfgs when is_list(cfgs) -> cfgs |> Enum.map(fn cfg -> {prot, cfg} end)
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
      # a shared rule may list two paths with the same pattern ({:get, p} and
      # {:head, p}): count it once per request
      |> Map.new(fn {chunks, prots} ->
        {chunks, Enum.uniq_by(prots, fn {_, cfg} -> cfg.id end)}
      end)

    TemplateHelper.compile(
      %{
        ip_registers: ip_registers,
        request_path_registers: request_path_registers
      },
      "engine"
    )
  end

  defp put_ip_keys(key) do
    Application.put_env(
      :phoenix_ddos,
      key,
      Application.get_env(:phoenix_ddos, key, [])
      |> Enum.flat_map(&ip_key(key, &1))
      |> Enum.uniq()
    )
  end

  # a bad entry must not take the whole protection down (configure may run at
  # runtime, from a telemetry handler): it is logged and skipped
  defp ip_key(key, entry) do
    [PhoenixDDoS.IP.normalize!(entry)]
  rescue
    ArgumentError ->
      # "" from a trailing comma in an env var: nothing to report
      if String.trim(to_string(entry)) != "",
        do: Logger.error("🛡️ PhoenixDDoS: invalid ip #{inspect(entry)} in #{key}, ignored")

      []
  end

  # --------------------------------------------------------------
  # Routers introspection
  # --------------------------------------------------------------

  defp phoenix_routers do
    Application.loaded_applications()
    |> Enum.map(fn {app, _desc, _v} -> app end)
    |> Enum.map(fn app ->
      # an app loaded without modules (or unloaded meanwhile) has none
      case :application.get_key(app, :modules) do
        {:ok, modules} -> modules
        _ -> []
      end
    end)
    |> List.flatten()
    |> Enum.filter(&phoenix_router?/1)
  end

  def phoenix_router?(module) when is_atom(module) do
    case module |> inspect() |> String.contains?("Router") && Code.ensure_loaded?(module) do
      true -> function_exported?(module, :__routes__, 0)
      _ -> false
    end
  end

  # --------------------------------------------------------------
  # Validation
  # --------------------------------------------------------------

  defp validate! do
    case Application.fetch_env(:phoenix_ddos, :ipv6_prefix) do
      :error ->
        :ok

      {:ok, p} when is_integer(p) and p in 0..128 ->
        :ok

      {:ok, other} ->
        raise ArgumentError, ":ipv6_prefix must be an integer in 0..128, got: #{inspect(other)}"
    end
  end

  # --------------------------------------------------------------
  # Helpers
  # --------------------------------------------------------------

  defp fetch_protection_configurations(prot) do
    Application.get_env(:phoenix_ddos, :protections, [])
    |> Enum.filter(fn {p, _} -> p == prot end)
  end

  defp put_sentence(%{jail_time: nil} = cfg), do: cfg |> Map.put(:sentence, :block)
  defp put_sentence(%{jail_time: _} = cfg), do: cfg |> Map.put(:sentence, :jail)

  defp put_sentence(cfg), do: cfg |> Map.put(:jail_time, default_jail_time()) |> put_sentence()

  defp default_jail_time, do: Application.get_env(:phoenix_ddos, :jail_time, {15, :minutes})

  # transform "/admin/:id/dashboard" to "_, "admin", _, "dashboard""
  # transform {:get, "/admin/:id/dashboard"} to ""GET", "admin", _, "dashboard""
  # empty segments are dropped, like the engine does on the request path
  # the engine counts HEAD as GET (Phoenix serves HEAD with GET routes)
  @http_methods [:get, :post, :delete, :head, :put, :patch, :options]
  defp path_to_pattern_match_chunk({:head, path}), do: path_to_pattern_match_chunk({:get, path})

  defp path_to_pattern_match_chunk({method, path}) when method in @http_methods do
    path_to_pattern_match_chunk(path, String.upcase("\"#{method}\""))
  end

  defp path_to_pattern_match_chunk({method, _path}), do: raise("unknown method #{method}")

  defp path_to_pattern_match_chunk(path, method \\ "_") do
    chunks =
      for chunk <- String.split(path, "/"), chunk != "" do
        case chunk do
          <<":", _rest::binary>> -> "_"
          # an escaped string literal, the pattern is compiled as code
          chunk -> inspect(chunk)
        end
      end

    Enum.join([method | chunks], ", ")
  end
end
