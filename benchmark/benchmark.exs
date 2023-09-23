
# 1 ip 500 ip
# 1 path 500 path
# 1 1 500 ip 500 path

tests = []

time = 10_000

Benchmark.put_prots(:ip, 1)
tests  = [ {"1 ip 1 rate limit", Benchmark.mesure_run(time)} | tests]

Benchmark.put_prots(:ip, 10)
tests  = [ {"10 ips 10 rate limits", Benchmark.mesure_run(time)} | tests]

Benchmark.put_prots(:ip, 500)
tests  = [ {"500 ips 500 rate limits", Benchmark.mesure_run(time)} | tests]

Benchmark.put_prots(:path, 1)
tests  = [ {"1 path 1 rate limit", Benchmark.mesure_run(time)} | tests]

Benchmark.put_prots(:path, 500)
tests  = [ {"500 paths 1 rate limit", Benchmark.mesure_run(time)} | tests]

Benchmark.flush_prots()

Application.put_env(:phoenix_ddos, :safelist_ips, ['1.2.3.4'])
PhoenixDDoS.Configure.init()
tests  = [ {"1 safelisted ip ", Benchmark.mesure_run(time)} | tests]

# I know 1.2.3.500 can't exist but the benchmark is valid !
Application.put_env(:phoenix_ddos, :safelist_ips, (1..500) |> Enum.map(fn i -> "1.2.3.#{i}" end))
PhoenixDDoS.Configure.init()
tests  = [ {"500 safelisted ips", Benchmark.mesure_run(time)} | tests]

Application.put_env(:phoenix_ddos, :blocklist_ips, ['1.2.3.4'])
PhoenixDDoS.Configure.init()
tests  = [ {"1 blocklisted ip ", Benchmark.mesure_run(time)} | tests]

# I know 1.2.3.500 can't exist but the benchmark is valid !
Application.put_env(:phoenix_ddos, :blocklist_ips, (1..500) |> Enum.map(fn i -> "1.2.3.#{i}" end))
PhoenixDDoS.Configure.init()
tests  = [ {"500 blocklisted ips", Benchmark.mesure_run(time)} | tests]


# ip whitelist/blacklist

IO.inspect(tests)

IO.puts("\n\nresults:")
IO.puts("| Configuration             | Speed                        |")
IO.puts("| :------------------------ | :--------------------------- |")

tests
|> Enum.reverse()
|> Enum.each(fn {name, elapse_ms} ->
  IO.puts("| #{String.pad_leading(name, 25)} | #{elapse_ms |> Benchmark.print_speed( time) |> String.pad_leading(28)} |")
end)


# 0
# 37
# 26
# 18
# 2252

# 0
# 28
# 26
# 14
# 25


# # ------------------------------------------
# # when ip is in jail
# PhoenixDDoS.Jail.send('127.0.0.1', {:test, %{jail_time: {5, :hours}}})

# Benchmark.put_prots(:classic)
# classic = Benchmark.mesure_run(time)

# Benchmark.put_prots(:one_ip)
# one_ip = Benchmark.mesure_run(time)

# Benchmark.put_prots(:one_path)
# one_path = Benchmark.mesure_run(time)

# Benchmark.put_prots(:extreme)
# extreme = Benchmark.mesure_run(time)


# IO.puts(dry)
# IO.puts(classic)
# IO.puts(one_ip)
# IO.puts(one_path)
# IO.puts(extreme)

# # 0
# # 51
# # 44
# # 43
# # 37

# # 0
# # 54
# # 32
# # 44
# # 40
