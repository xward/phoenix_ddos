defmodule PhoenixDDoS.IpRateLimit do
  @moduledoc false

  use PhoenixDDoS.Protection

  def rate_key(id, ip), do: "ip_#{id}_#{ip}"

  def prepare_config(cfg), do: cfg
end
