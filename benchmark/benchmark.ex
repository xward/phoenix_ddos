defmodule Benchmark do
  use Plug.Test

  import PhoenixDDoS.DDOSUtils

  alias PhoenixDDoS.Time

  def mesure_run(amount \\ 10_000) do
    conn = conn(:get, "/")

    start = Time.now()

    1..amount
    |> Enum.each(fn _ ->
      PhoenixDDoS.call(conn, [])
    end)

    Time.diff_ms(start)
  end

  def flush_prots do
    [] |> put_protections()
  end

  def put_prots(:one_ip) do
    [
      {PhoenixDDoS.IpRateLimit, allowed: 10_000, period: {2, :minute}}
    ]
    |> put_protections()
  end

  def put_prots(:one_path) do
    [
      {PhoenixDDoS.IpRateLimitPerRequestPath,
       request_paths: ["/admin"], allowed: 3, period: {1, :minute}}
    ]
    |> put_protections()
  end

  def put_prots(:a10_ips) do
    (1..10)
    |> Enum.map(fn i ->
      {PhoenixDDoS.IpRateLimit, allowed: 10_000, period: {i, :minute}}
    end)
    |> put_protections()
  end

  def put_prots(:a500_paths) do
    [
      {PhoenixDDoS.IpRateLimitPerRequestPath,
       request_paths: 1..500 |> Enum.map(fn i -> "/admin#{i}:id/user/#{i * 2}" end),
       allowed: 50,
       period: {1, :hour}}
    ]
    |> put_protections()
  end



end
