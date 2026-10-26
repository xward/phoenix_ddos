defmodule PhoenixDDoS.RateLimitTest do
  use ExUnit.Case, async: false
  use Plug.Test

  import PhoenixDDoS.DDOSUtils

  alias PhoenixDDoS.RateLimit

  setup do
    Cachex.clear(:phoenix_ddos_store)
    Cachex.clear(:phoenix_ddos_jail)
    Application.put_env(:phoenix_ddos, :safelist_ips, [])
    Application.put_env(:phoenix_ddos, :blocklist_ips, [])
    flush_protections()
    :ok
  end

  test "window_key changes when the window changes" do
    assert RateLimit.window_key("k", 1_000, 1_999) == "k_1"
    assert RateLimit.window_key("k", 1_000, 2_000) == "k_2"
  end

  test "fresh quota right after window end" do
    [{PhoenixDDoS.IpRateLimit, allowed: 5, period: {1, :second}, jail_time: nil}]
    |> put_protections()

    Cachex.purge(:phoenix_ddos_store)
    conn = conn(:get, "/") |> Map.put(:remote_ip, {7, 7, 7, 7})

    # ensure the 5 requests do not straddle a window boundary
    Process.sleep(1_000 - rem(System.os_time(:millisecond), 1_000) + 20)
    for _ <- 1..5, do: conn |> call() |> assert_allowed()
    conn |> call() |> assert_rejected()

    Process.sleep(1_200)
    for _ <- 1..5, do: conn |> call() |> assert_allowed()
  end
end
