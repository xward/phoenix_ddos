defmodule PhoenixDDoS.StoreTest do
  use ExUnit.Case, async: false

  import Plug.Test
  import PhoenixDDoS.DDOSUtils

  alias PhoenixDDoS.Ban
  alias PhoenixDDoS.Jail
  alias PhoenixDDoS.Store.Server

  defmodule TestStore do
    @moduledoc "forwards every call to the test process, serves the bans given in opts at boot"
    @behaviour PhoenixDDoS.Store

    def init(opts) do
      if Application.get_env(:phoenix_ddos, :test_store_down),
        do: {:error, :down},
        else: {:ok, Map.new(opts)}
    end

    def insert_ban(state, ban, conn), do: reply(state, {:insert_ban, ban, conn})
    def release_ban(state, ip, released_at), do: reply(state, {:release_ban, ip, released_at})

    def active_bans(state, _now) do
      send(state.pid, :active_bans)
      {:ok, state[:active] || []}
    end

    defp reply(state, message) do
      send(state.pid, message)
      if state[:raise], do: raise("boom")
      state[:reply] || :ok
    end
  end

  @ip ~c"1.2.3.4"

  setup do
    Cachex.clear(:phoenix_ddos_store)
    Cachex.clear(:phoenix_ddos_jail)
    Cachex.clear(:phoenix_ddos_suspicious_ips)
    Application.put_env(:phoenix_ddos, :safelist_ips, [])
    Application.put_env(:phoenix_ddos, :blocklist_ips, [])
    Application.delete_env(:phoenix_ddos, :test_store_down)
    Application.delete_env(:phoenix_ddos, :store_retry_interval)
    put_protections([{PhoenixDDoS.IpRateLimit, allowed: 2, period: {1, :minute}}])

    on_exit(fn -> Application.delete_env(:phoenix_ddos, :store) end)
    :ok
  end

  test "without a store nothing is started and the jail works as before" do
    refute Process.whereis(Server)

    Jail.send(@ip, prot())
    assert Jail.in_jail?(@ip)
    assert %Ban{ip: "1.2.3.4", protection: "PhoenixDDoS.IpRateLimit"} = Jail.get("1.2.3.4")
    assert [%Ban{ip: "1.2.3.4"}] = Jail.bans()

    assert :ok = Jail.bail_out(@ip)
    refute Jail.in_jail?(@ip)
    assert Jail.bans() == []
  end

  test "a jailed ip is written to the store with its request, a bail out too" do
    start_store([])
    conn = conn(:get, "/admin") |> Map.put(:remote_ip, {1, 2, 3, 4})

    conn |> call() |> assert_allowed()
    conn |> call() |> assert_allowed()
    conn |> call() |> assert_rejected()

    assert_receive {:insert_ban, %Ban{} = ban, %Plug.Conn{request_path: "/admin"}}
    assert %Ban{ip: "1.2.3.4", protection: "PhoenixDDoS.IpRateLimit", metadata: %{}} = ban
    assert ban.reason == "PhoenixDDoS.IpRateLimit: more than 2 requests in 1 minute"
    assert DateTime.diff(ban.expires_at, ban.banned_at, :minute) == 15
    assert Jail.get(@ip) == ban

    Jail.bail_out("1.2.3.4")
    assert_receive {:release_ban, "1.2.3.4", %DateTime{}}
    refute Jail.in_jail?(@ip)
  end

  test "bans still active in the store go back to jail at boot, expired ones do not" do
    now = DateTime.utc_now()

    start_store(
      active: [
        stored_ban("10.0.0.1", DateTime.add(now, 3600, :second)),
        stored_ban("10.0.0.2", DateTime.add(now, -1, :second)),
        stored_ban("10.0.0.3", nil)
      ]
    )

    assert_receive :active_bans
    assert Enum.sort(Jail.ips_in_jail()) == ["10.0.0.1", "10.0.0.3"]
    assert %Ban{reason: "from the store"} = Jail.get("10.0.0.1")
    # nothing is written back to the store
    refute_receive {:insert_ban, _, _}
  end

  test "a store that fails never touches the jail nor the server" do
    attach_store_errors()
    start_store(reply: {:error, :boom})

    Jail.send(@ip, prot())
    assert_receive {:insert_ban, %Ban{ip: "1.2.3.4"}, nil}
    assert_receive {:store_error, %{operation: :insert_ban, reason: :boom}}
    assert Jail.in_jail?(@ip)
    assert Server.flush() == :ok
  end

  test "a store that raises never touches the jail nor the server" do
    attach_store_errors()
    start_store(raise: true)

    Jail.send(@ip, prot())
    assert_receive {:store_error, %{operation: :insert_ban, reason: %RuntimeError{}}}
    assert Jail.in_jail?(@ip)

    Jail.bail_out(@ip)
    assert_receive {:store_error, %{operation: :release_ban, reason: %RuntimeError{}}}
    refute Jail.in_jail?(@ip)
    assert Server.flush() == :ok
  end

  test "a store down at boot is retried, the bans made meanwhile wait for it" do
    attach_store_errors()
    Application.put_env(:phoenix_ddos, :test_store_down, true)
    Application.put_env(:phoenix_ddos, :store_retry_interval, 50)
    start_store([])
    assert_receive {:store_error, %{operation: :init, reason: :down}}

    Jail.send(@ip, prot())
    assert Jail.in_jail?(@ip)
    refute_receive {:insert_ban, _, _}, 100

    Application.delete_env(:phoenix_ddos, :test_store_down)
    assert_receive :active_bans, 1_000
    assert_receive {:insert_ban, %Ban{ip: "1.2.3.4"}, nil}
  end

  # --------------------------------------------------------------
  # helpers
  # --------------------------------------------------------------

  defp start_store(opts) do
    Application.put_env(:phoenix_ddos, :store, {TestStore, [pid: self()] ++ opts})
    start_supervised!(Server)
    Server.flush()
  end

  defp prot, do: :phoenix_ddos |> Application.get_env(:_prots) |> Enum.at(0)

  defp stored_ban(ip, expires_at) do
    %Ban{ip: ip, reason: "from the store", banned_at: DateTime.utc_now(), expires_at: expires_at}
  end

  defp attach_store_errors do
    :telemetry.attach(
      "store_test_#{inspect(self())}",
      [:phoenix_ddos, :store, :error],
      &__MODULE__.handle_event/4,
      %{pid: self()}
    )

    on_exit(fn -> :telemetry.detach("store_test_#{inspect(self())}") end)
  end

  def handle_event([:phoenix_ddos, :store, :error], _measurements, meta, %{pid: pid}) do
    send(pid, {:store_error, meta})
  end
end
