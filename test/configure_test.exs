defmodule PhoenixDDoS.ConfigureTest do
  use ExUnit.Case, async: false

  alias PhoenixDDoS.Configure

  test "init/0 works with a loaded app without modules" do
    :ok = :application.load({:application, :phoenix_ddos_fake, [vsn: ~c"0"]})
    on_exit(fn -> :application.unload(:phoenix_ddos_fake) end)

    Configure.init()
  end

  test "init/0 can run from many processes at once" do
    1..20
    |> Enum.map(fn _ -> Task.async(&Configure.init/0) end)
    |> Task.await_many(30_000)
  end

  test "init/0 skips blank and invalid ip list entries" do
    # e.g. "127.0.0.1, 9.9.9.9," |> String.split(",") from an env var
    Application.put_env(:phoenix_ddos, :safelist_ips, ["127.0.0.1", " 9.9.9.9", "", "not an ip"])
    on_exit(fn -> Application.put_env(:phoenix_ddos, :safelist_ips, []) end)

    log = ExUnit.CaptureLog.capture_log(fn -> Configure.init() end)

    assert Application.get_env(:phoenix_ddos, :safelist_ips) == [~c"127.0.0.1", ~c"9.9.9.9"]
    assert log =~ ~s(invalid ip "not an ip" in safelist_ips, ignored)
    refute log =~ ~s(invalid ip "")
  end

  test "init/0 rejects an invalid ipv6_prefix" do
    Application.put_env(:phoenix_ddos, :ipv6_prefix, 129)
    on_exit(fn -> Application.delete_env(:phoenix_ddos, :ipv6_prefix) end)

    assert_raise ArgumentError, ~r/ipv6_prefix/, fn -> Configure.init() end
  end
end
