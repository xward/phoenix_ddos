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

  def put_prots(:path, n) do
    [
      {PhoenixDDoS.IpRateLimitPerRequestPath,
       request_paths: 1..n |> Enum.map(fn i -> "/admin#{i}:id/user/#{i * 2}" end),
       allowed: 50,
       period: {1, :hour}}
    ]
    |> put_protections()
  end

  def put_prots(:ip, n) do
    1..n
    |> Enum.map(fn i ->
      {PhoenixDDoS.IpRateLimit, allowed: 10_000, period: {i, :minute}}
    end)
    |> put_protections()
  end

  # <span style="color:blue">some *blue* text</span>.
  def print_speed(elapse_ms, count) do
    cost = elapse_ms * 10_000 / count

    "#{round(cost)} ms per 10_000 queries"
  end
end
