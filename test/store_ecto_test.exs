defmodule PhoenixDDoS.StoreEctoTest do
  use ExUnit.Case, async: false

  import Plug.Test
  import PhoenixDDoS.DDOSUtils

  alias PhoenixDDoS.Ban
  alias PhoenixDDoS.Jail
  alias PhoenixDDoS.Store.Ecto, as: EctoStore
  alias PhoenixDDoS.Store.Ecto.Schema
  alias PhoenixDDoS.Store.Server
  alias PhoenixDDoS.TestRepo

  defmodule UserStore do
    @moduledoc "the pattern documented in PhoenixDDoS.Store: the Ecto store plus the request's data"
    @behaviour PhoenixDDoS.Store

    @impl true
    defdelegate init(opts), to: EctoStore
    @impl true
    defdelegate release_ban(state, ip, released_at), to: EctoStore
    @impl true
    defdelegate active_bans(state, now), to: EctoStore

    @impl true
    def insert_ban(state, ban, %Plug.Conn{} = conn) do
      metadata = %{user_id: conn.assigns[:user_id], note: "caught on #{conn.request_path}"}
      EctoStore.insert_ban(state, %{ban | metadata: metadata}, conn)
    end

    def insert_ban(state, ban, nil), do: EctoStore.insert_ban(state, ban, nil)
  end

  setup_all do
    File.rm(Application.get_env(:phoenix_ddos, TestRepo)[:database])
    {:ok, _} = TestRepo.start_link()

    Ecto.Migrator.run(TestRepo, [{0, TestRepo.Migrations.AddPhoenixDdosBans}], :up,
      all: true,
      log: false
    )

    :ok
  end

  setup do
    TestRepo.delete_all(Schema)
    Cachex.clear(:phoenix_ddos_jail)
    put_protections([{PhoenixDDoS.IpRateLimit, allowed: 2, period: {1, :minute}}])

    on_exit(fn -> Application.delete_env(:phoenix_ddos, :store) end)
    :ok
  end

  test "insert, active and release" do
    assert {:error, _} = EctoStore.init([])
    {:ok, state} = EctoStore.init(repo: TestRepo)
    now = DateTime.utc_now()

    {:ok, _} = EctoStore.insert_ban(state, ban("10.0.0.1", 3600, %{user_id: 42}), nil)
    {:ok, _} = EctoStore.insert_ban(state, ban("10.0.0.2", -1), nil)
    {:ok, _} = EctoStore.insert_ban(state, ban("10.0.0.3", nil), nil)

    {:ok, bans} = EctoStore.active_bans(state, now)

    assert [
             %Ban{ip: "10.0.0.1", reason: "test", metadata: %{"user_id" => 42}},
             %Ban{ip: "10.0.0.3", expires_at: nil, metadata: %{}}
           ] = Enum.sort_by(bans, & &1.ip)

    assert :ok = EctoStore.release_ban(state, "10.0.0.1", DateTime.utc_now())
    assert {:ok, [%Ban{ip: "10.0.0.3"}]} = EctoStore.active_bans(state, DateTime.utc_now())
  end

  test "bans go to the database and come back in jail after a restart" do
    Application.put_env(:phoenix_ddos, :store, {EctoStore, repo: TestRepo})
    start_supervised!(Server)

    Jail.send(~c"1.2.3.4", prot())
    Server.flush()
    assert [%Schema{ip: "1.2.3.4", released_at: nil, reason: reason}] = TestRepo.all(Schema)
    assert reason =~ "PhoenixDDoS.IpRateLimit"

    restart_server()
    assert Jail.in_jail?("1.2.3.4")

    Jail.bail_out("1.2.3.4")
    Server.flush()
    assert [%Schema{released_at: %DateTime{}}] = TestRepo.all(Schema)

    restart_server()
    refute Jail.in_jail?("1.2.3.4")
  end

  test "a store wrapping the Ecto one records the request's data" do
    Application.put_env(:phoenix_ddos, :store, {UserStore, repo: TestRepo})
    start_supervised!(Server)

    conn = conn(:get, "/admin") |> Plug.Conn.assign(:user_id, 7)
    Jail.send(~c"1.2.3.4", prot(), conn)
    Server.flush()

    assert [%Schema{metadata: %{"user_id" => 7, "note" => "caught on /admin"}}] =
             TestRepo.all(Schema)
  end

  # --------------------------------------------------------------
  # helpers
  # --------------------------------------------------------------

  defp prot, do: :phoenix_ddos |> Application.get_env(:_prots) |> Enum.at(0)

  defp ban(ip, expires_in_seconds, metadata \\ %{}) do
    now = DateTime.utc_now()

    %Ban{
      ip: ip,
      reason: "test",
      protection: "PhoenixDDoS.IpRateLimit",
      banned_at: now,
      expires_at: expires_in_seconds && DateTime.add(now, expires_in_seconds, :second),
      metadata: metadata
    }
  end

  # simulate a restart: the jail is empty, the server reloads it from the database
  defp restart_server do
    stop_supervised!(Server)
    Cachex.clear(:phoenix_ddos_jail)
    start_supervised!(Server)
    Server.flush()
  end
end
