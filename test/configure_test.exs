defmodule PhoenixDDoS.ConfigureTest do
  use ExUnit.Case, async: false

  alias PhoenixDDoS.Configure

  test "phoenix_routers/0 ignores loaded apps without modules" do
    :ok = :application.load({:application, :phoenix_ddos_fake, [vsn: ~c"0"]})
    on_exit(fn -> :application.unload(:phoenix_ddos_fake) end)

    assert is_list(Configure.phoenix_routers())
    assert Configure.phoenix_routers([:phoenix_ddos_fake]) == []
  end

  test "phoenix_routers/1 ignores apps unloaded meanwhile" do
    assert Configure.phoenix_routers([:phoenix_ddos_not_loaded]) == []
  end
end
