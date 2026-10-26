# sqlite repo exercising PhoenixDDoS.Store.Ecto, see test/support/test_repo.ex
Application.put_env(:phoenix_ddos, PhoenixDDoS.TestRepo,
  database: Path.join(System.tmp_dir!(), "phoenix_ddos_test.db"),
  pool_size: 1
)

ExUnit.start(capture_log: true)
