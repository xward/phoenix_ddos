defmodule PhoenixDDoS.IpRateLimitPerRequestPath do
  @moduledoc false

  use PhoenixDDoS.Protection

  def rate_key(id, ip), do: "ippath_#{id}_#{ip}"

  def prepare_config(%{shared: true} = cfg), do: cfg

  def prepare_config(cfg) do
    # split in multiple configs
    cfg.request_paths
    |> Enum.map(fn request_path -> cfg |> Map.put(:request_paths, [request_path]) end)
  end
end
