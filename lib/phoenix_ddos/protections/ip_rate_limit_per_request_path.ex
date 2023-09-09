defmodule PhoenixDDOS.IpRateLimitPerRequestPath do
  @moduledoc """
  check if an ip ddos on specific paths
  """

  use PhoenixDDOS.Protection

  def check({reject, request}) do
    {__MODULE__
     |> Config.get!()
     |> Enum.reduce(reject, fn {id, paths, window_ms, count}, acc ->
       if path_match?(request.request_path, paths) do
         Cache.incr_check("ippath_#{id}_#{request.ip}", window_ms, count) || acc
       else
         acc
       end
     end), request}
  end

  # from {PhoenixDDOS.IpRateLimitPerRequestPath, request_paths: ["/user", "/admin"], allowed: 20, period: {1, :minute}}
  # to [{"123", ["/user"], 60_000, 500}, {"123", ["/admin"], 60_000, 500}]
  # or
  # from {PhoenixDDOS.IpRateLimitPerRequestPath, request_paths: ["/user", "/admin"],
  #       shared: true, allowed: 20, period: {1, :minute}}
  # to {"123", ["/user", "/admin"], 60_000, 500}
  def prepare_config(cfg) do
    if Keyword.get(cfg, :shared) == true do
      {Config.rand_id(), Keyword.get(cfg, :request_paths),
       Config.period_to_msec(Keyword.get(cfg, :period)), Keyword.get(cfg, :allowed)}
    else
      Keyword.get(cfg, :request_paths)
      |> Enum.map(fn path ->
        {Config.rand_id(), [path], Config.period_to_msec(Keyword.get(cfg, :period)),
         Keyword.get(cfg, :allowed)}
      end)
    end
  end

  defp path_match?(request_path, paths) do
    request_path in paths
  end
end
