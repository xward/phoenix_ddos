defmodule PhoenixDDoSTest do
  @moduledoc """
  All ddos test can't be run async
  """

  use ExUnit.Case, async: false
  use Plug.Test

  doctest PhoenixDDoS

  import PhoenixDDoS.DDOSUtils

  alias PhoenixDDoS.Test.TelemetryUtils

  @an_ip {1, 2, 3, 4}
  @an_ip_charlist @an_ip |> :inet.ntoa()
  @another_ip {1, 2, 3, 5}

  describe "call/2" do
    setup do
      Cachex.clear(:phoenix_ddos_store)
      Cachex.clear(:phoenix_ddos_jail)
      Application.put_env(:phoenix_ddos, :safelist_ips, [])
      Application.put_env(:phoenix_ddos, :blocklist_ips, [])
      flush_protections()

      # https://elixirforum.com/t/testing-and-telemetry-events-how-to-test-if-they-are-sent/28273
      :telemetry.attach_many(
        "unit_test_telemetry",
        [[:phoenix_ddos, :jail, :new], [:phoenix_ddos, :request, :new]],
        &TelemetryUtils.handle_telemetry_event/4,
        nil
      )

      on_exit(fn -> :telemetry.detach("unit_test_telemetry") end)

      :ok
    end

    test "safelist_ips" do
      # let mix ip format
      Application.put_env(:phoenix_ddos, :safelist_ips, [
        @an_ip |> :inet.ntoa() |> to_string(),
        @another_ip |> :inet.ntoa()
      ])

      [
        {PhoenixDDoS.IpRateLimit, allowed: 0, period: {2, :second}}
      ]
      |> put_protections()

      run_ddos(conn(), :never_fail)
      run_ddos(conn(%{remote_ip: @another_ip}), :never_fail)
    end

    test "blocklist_ips" do
      Application.put_env(:phoenix_ddos, :blocklist_ips, [@an_ip |> :inet.ntoa()])
      PhoenixDDoS.Configure.init()

      run_ddos(conn(), :always_fail)
    end

    test "IpRateLimit with jail" do
      [
        {PhoenixDDoS.IpRateLimit, allowed: 10, period: {2, :second}}
      ]
      |> put_protections()

      assert_not_in_jail(@an_ip)
      start_early_in_window({2, :second})
      run_ddos(conn(), assert_fail_after_request: 10)
      assert_in_jail(@an_ip)

      assert_receive {:telemetry_event, [:phoenix_ddos, :jail, :new], %{}, %{ip: @an_ip_charlist}}

      :timer.sleep(3000)
      # still blocked, even if we waited more than period
      run_ddos(conn(), :always_fail)
    end

    test "IpRateLimit multiple ip" do
      [
        {PhoenixDDoS.IpRateLimit, allowed: 10, period: {2, :second}}
      ]
      |> put_protections()

      start_early_in_window({2, :second})
      run_ddos(conn(), assert_fail_after_request: 10)

      run_ddos(conn(%{remote_ip: @another_ip}), assert_fail_after_request: 10)
    end

    test "IpRateLimit throttle" do
      [
        {PhoenixDDoS.IpRateLimit, allowed: 10, period: {2, :second}, jail_time: nil}
      ]
      |> put_protections()

      start_early_in_window({2, :second})
      run_ddos(conn(), assert_fail_after_request: 10)
      assert_not_in_jail(@an_ip)

      :timer.sleep(3000)
      # fresh quota
      start_early_in_window({2, :second})
      run_ddos(conn(), assert_fail_after_request: 10)
    end

    test "IpRateLimit bench" do
      [
        {PhoenixDDoS.IpRateLimit, allowed: 10_000, period: {2, :second}},
        {PhoenixDDoS.IpRateLimitPerRequestPath,
         request_paths: ["/admin"], allowed: 3, period: {1, :minute}}
      ]
      |> put_protections()

      start_early_in_window({2, :second})
      start = PhoenixDDoS.Time.now()
      run_ddos(conn(), assert_fail_after_request: 10_000)

      diff = PhoenixDDoS.Time.diff_ms(start)
      # 55-110 ms per 10k on a dev machine under load: a gross-regression guard,
      # not a benchmark (see `mix benchmark`), so the bound leaves headroom
      assert diff < 500, "quick bench tool #{round(diff)}ms > 500 ms"
    end

    test "IpRateLimitPerRequestPath" do
      [
        {PhoenixDDoS.IpRateLimitPerRequestPath,
         request_paths: ["/admin/:id/dashboard", {:post, "/admin"}],
         allowed: 3,
         period: {1, :minute},
         jail_time: nil}
      ]
      |> put_protections()

      run_ddos(path_conn("/admin/23/dashboard"), assert_fail_after_request: 3)

      run_ddos(path_conn("/admin", "POST"), assert_fail_after_request: 3)

      run_ddos(path_conn("/admin"), :never_fail)

      run_ddos(path_conn("/user"), :never_fail)
    end

    test "IpRateLimitPerRequestPath counts every spelling the router serves as the same path" do
      [
        {PhoenixDDoS.IpRateLimitPerRequestPath,
         request_paths: ["/admin", "/admin/:id/dashboard"],
         allowed: 3,
         period: {1, :minute},
         jail_time: nil}
      ]
      |> put_protections()

      # all routed by phoenix to /admin: they must share its quota
      ["/admin", "//admin", "/admin/"] |> Enum.each(&(path_conn(&1) |> call()))
      run_ddos(path_conn("/%61dmin"), :always_fail)

      run_ddos(path_conn("/admin//23/dashboard"), assert_fail_after_request: 3)
      run_ddos(path_conn("/admin/23/dashboard/"), :always_fail)

      run_ddos(path_conn("/user"), :never_fail)
      run_ddos(path_conn("/admin%zz"), :never_fail)
    end

    test "IpRateLimitPerRequestPath shared quota along all paths" do
      [
        {PhoenixDDoS.IpRateLimitPerRequestPath,
         request_paths: ["/admin", "/user"],
         allowed: 3,
         shared: true,
         jail_time: nil,
         period: {1, :minute}}
      ]
      |> put_protections()

      run_ddos(path_conn("/admin"), assert_fail_after_request: 3)

      run_ddos(path_conn("/user"), :always_fail)
    end

    # --------------------------------------------------------------
    # telemetry events
    # --------------------------------------------------------------

    test "Telemetry context data" do
      conn = path_conn("/admin/521/dashboard")
      conn |> call()

      assert_receive {:telemetry_event, [:phoenix_ddos, :request, :new], %{},
                      %{
                        ip: "1.2.3.4",
                        method: "GET",
                        path: "/admin/521/dashboard",
                        route: "[PhoenixDDoS.Router /admin/:id/dashboard]"
                      }}
    end

    test "Telemetry context no route found" do
      conn = path_conn("/notfound")
      conn |> call()

      assert_receive {:telemetry_event, [:phoenix_ddos, :request, :new], %{},
                      %{
                        ip: "1.2.3.4",
                        method: "GET",
                        path: "/notfound",
                        route: "unknown route"
                      }}
    end

    test "Telemetry [:phoenix_ddos, :request, :new] :pass" do
      conn() |> call()

      assert_receive {:telemetry_event, [:phoenix_ddos, :request, :new], %{}, %{decision: :pass}}
    end

    test "Telemetry [:phoenix_ddos, :request, :new] :block on blocklist_ips" do
      Application.put_env(:phoenix_ddos, :blocklist_ips, [@an_ip |> :inet.ntoa()])
      PhoenixDDoS.Configure.init()

      conn() |> call()

      assert_receive {:telemetry_event, [:phoenix_ddos, :request, :new], %{}, %{decision: :block}}
    end

    test "blocklisted request does not resolve route" do
      Application.put_env(:phoenix_ddos, :blocklist_ips, [@an_ip |> :inet.ntoa()])
      PhoenixDDoS.Configure.init()

      previous_routers = Application.get_env(:phoenix_ddos, :routers)
      Application.put_env(:phoenix_ddos, :routers, [PhoenixDDoS.CountingRouter])
      :telemetry.detach("unit_test_telemetry")

      on_exit(fn -> Application.put_env(:phoenix_ddos, :routers, previous_routers) end)

      Process.put(:counting_router_calls, 0)
      conn() |> call() |> assert_rejected()

      assert PhoenixDDoS.CountingRouter.calls() == 0
    end

    test "ip released from jail gets a fresh quota" do
      [
        {PhoenixDDoS.IpRateLimit, allowed: 3, period: {1, :hour}, jail_time: {1, :second}}
      ]
      |> put_protections()

      1..3 |> Enum.each(fn _ -> conn() |> call() |> assert_allowed() end)
      conn() |> call() |> assert_rejected()
      assert_in_jail(@an_ip)

      Process.sleep(1_100)
      Cachex.purge(:phoenix_ddos_jail)
      assert_not_in_jail(@an_ip)

      conn() |> call() |> assert_allowed()
    end

    test "Telemetry [:phoenix_ddos, :request, :new] :jail" do
      [
        {PhoenixDDoS.IpRateLimit, allowed: 0, period: {2, :second}}
      ]
      |> put_protections()

      conn() |> call()

      assert_receive {:telemetry_event, [:phoenix_ddos, :request, :new], %{}, %{decision: :jail}}
    end

    test "Telemetry [:phoenix_ddos, :request, :new] :block" do
      [
        {PhoenixDDoS.IpRateLimit, allowed: 0, period: {2, :second}, jail_time: nil}
      ]
      |> put_protections()

      conn() |> call()

      assert_receive {:telemetry_event, [:phoenix_ddos, :request, :new], %{}, %{decision: :block}}
    end

    test "jail alerts are capped per minute" do
      Application.put_env(:phoenix_ddos, :max_jail_alerts_per_minute, 3)
      on_exit(fn -> Application.delete_env(:phoenix_ddos, :max_jail_alerts_per_minute) end)

      [
        {PhoenixDDoS.IpRateLimit, allowed: 0, period: {2, :second}, jail_time: {1, :minute}}
      ]
      |> put_protections()

      # The cap is per wall-clock minute: if a minute boundary falls inside a run
      # (milliseconds long, so very unlikely) the counts could split, so retry the run.
      log = capture_jail_run_within_one_minute(fn -> jail_ips(1..10) end)

      assert length(Regex.scan(~r/goes to JAIL/, log)) == 3
      assert length(Regex.scan(~r/alerts suppressed/, log)) == 1
    end

    test "jail alert cap survives a rate-limit store reset (eviction)" do
      Application.put_env(:phoenix_ddos, :max_jail_alerts_per_minute, 2)
      on_exit(fn -> Application.delete_env(:phoenix_ddos, :max_jail_alerts_per_minute) end)

      [
        {PhoenixDDoS.IpRateLimit, allowed: 0, period: {2, :second}, jail_time: {1, :minute}}
      ]
      |> put_protections()

      log =
        capture_jail_run_within_one_minute(fn ->
          jail_ips(1..2)
          Cachex.clear(:phoenix_ddos_store)
          jail_ips(3..4)
        end)

      assert length(Regex.scan(~r/goes to JAIL/, log)) == 2
      assert length(Regex.scan(~r/alerts suppressed/, log)) == 1
    end
  end

  defp conn(attr \\ %{}) do
    conn(:get, "/") |> Map.put(:remote_ip, @an_ip) |> Map.merge(attr)
  end

  # the engine matches on path_info, like Phoenix.Router
  defp path_conn(path, method \\ "GET") do
    %{
      conn(%{request_path: path, method: method})
      | path_info: for(s <- String.split(path, "/"), s != "", do: s)
    }
  end

  # Rate-limit windows are aligned on the wall clock (RateLimit.window_key/3):
  # a run asserting an exact rejection point must not straddle a window
  # boundary. Start it with at least half a window ahead (runs take a few ms).
  defp start_early_in_window(period) do
    period_ms = PhoenixDDoS.Time.period_to_msec(period)
    left = period_ms - rem(System.os_time(:millisecond), period_ms)
    if left < div(period_ms, 2), do: Process.sleep(left + 10)
  end

  defp jail_ips(range), do: for(i <- range, do: conn(%{remote_ip: {7, 7, 7, i}}) |> call())

  defp capture_jail_run_within_one_minute(run) do
    Cachex.clear(:phoenix_ddos_store)
    Cachex.clear(:phoenix_ddos_jail)
    Cachex.clear(:phoenix_ddos_alerts)
    minute = div(System.os_time(:millisecond), 60_000)

    log = ExUnit.CaptureLog.capture_log(run)

    if div(System.os_time(:millisecond), 60_000) == minute,
      do: log,
      else: capture_jail_run_within_one_minute(run)
  end
end
