defmodule PhoenixDDoS.RequestPathTest do
  use ExUnit.Case, async: false
  use Plug.Test

  import PhoenixDDoS.DDOSUtils

  @ip {1, 2, 3, 40}

  setup do
    Cachex.clear(:phoenix_ddos_store)
    Cachex.clear(:phoenix_ddos_jail)
    Application.put_env(:phoenix_ddos, :safelist_ips, [])
    Application.put_env(:phoenix_ddos, :blocklist_ips, [])
    on_exit(&flush_protections/0)
    :ok
  end

  # mimic Plug.Cowboy: raw request_path, path_info without empty segments
  defp raw_conn(method, raw) do
    conn(method, "/")
    |> Map.merge(%{
      request_path: raw,
      path_info: for(s <- String.split(raw, "/"), s != "", do: s),
      remote_ip: @ip
    })
  end

  test "all spellings of the path share one quota" do
    for raw <- ["/admin", "/admin/", "//admin", "/%61dmin"] do
      Cachex.clear(:phoenix_ddos_store)

      put_protections([
        {PhoenixDDoS.IpRateLimitPerRequestPath,
         request_paths: ["/admin"], allowed: 3, period: {1, :minute}, jail_time: nil}
      ])

      run_ddos(raw_conn(:get, raw), %{assert_fail_after_request: 3})
    end
  end

  test "spellings are cumulated" do
    put_protections([
      {PhoenixDDoS.IpRateLimitPerRequestPath,
       request_paths: ["/admin"], allowed: 3, period: {1, :minute}, jail_time: nil}
    ])

    for raw <- ["/admin", "/admin/", "//admin"],
        do: raw |> then(&raw_conn(:get, &1)) |> call() |> assert_allowed()

    raw_conn(:get, "/%61dmin") |> call() |> assert_rejected()
  end

  test "HEAD counts for a GET rule" do
    put_protections([
      {PhoenixDDoS.IpRateLimitPerRequestPath,
       request_paths: [{:get, "/admin"}], allowed: 3, period: {1, :minute}, jail_time: nil}
    ])

    run_ddos(raw_conn("HEAD", "/admin") |> Map.put(:method, "HEAD"), %{
      assert_fail_after_request: 3
    })
  end

  test "a HEAD rule counts HEAD and GET requests (Phoenix serves HEAD with GET routes)" do
    put_protections([
      {PhoenixDDoS.IpRateLimitPerRequestPath,
       request_paths: [{:head, "/admin"}], allowed: 3, period: {1, :hour}, jail_time: nil}
    ])

    head = raw_conn("HEAD", "/admin") |> Map.put(:method, "HEAD")
    get = raw_conn(:get, "/admin")

    head |> call() |> assert_allowed()
    get |> call() |> assert_allowed()
    head |> call() |> assert_allowed()
    get |> call() |> assert_rejected()
    head |> call() |> assert_rejected()

    raw_conn(:get, "/user") |> call() |> assert_allowed()
  end

  test "a shared rule listing the GET and HEAD of a path counts a request once" do
    put_protections([
      {PhoenixDDoS.IpRateLimitPerRequestPath,
       request_paths: [{:get, "/admin"}, {:head, "/admin"}],
       shared: true,
       allowed: 3,
       period: {1, :hour},
       jail_time: nil}
    ])

    run_ddos(raw_conn(:get, "/admin"), %{assert_fail_after_request: 3})
  end

  test "POST counts for a DELETE rule (method override)" do
    put_protections([
      {PhoenixDDoS.IpRateLimitPerRequestPath,
       request_paths: [{:delete, "/admin"}], allowed: 3, period: {1, :minute}, jail_time: nil}
    ])

    run_ddos(raw_conn("POST", "/admin") |> Map.put(:method, "POST"), %{
      assert_fail_after_request: 3
    })
  end

  test "placeholders still work" do
    put_protections([
      {PhoenixDDoS.IpRateLimitPerRequestPath,
       request_paths: ["/admin/:id/dashboard"], allowed: 3, period: {1, :minute}, jail_time: nil}
    ])

    run_ddos(raw_conn(:get, "/admin/42/dashboard"), %{assert_fail_after_request: 3})
  end
end
