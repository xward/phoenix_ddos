defmodule Bench do

  def func do
    start=DateTime.utc_now
    (1..500_000)
    |> Enum.each(fn _ -> a() end)
    IO.puts(DateTime.diff(DateTime.utc_now, start, :millisecond))
  end

  def cachex do
    Cachex.put(:phoenix_ddos_store, :a, %{a: 2})
    start=DateTime.utc_now
    (1..500_000)
    |> Enum.each(fn _ ->
      {:ok, %{a: a}} = Cachex.get(:phoenix_ddos_store, :a)

    end)
    IO.puts(DateTime.diff(DateTime.utc_now, start, :millisecond))
  end


  @cfg %{a: 2}

  def a, do: @cfg.a
end
