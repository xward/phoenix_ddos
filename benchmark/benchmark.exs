
# 1 ip 500 ip
# 1 path 500 path
# 1 1 500 ip 500 path


time = 10_000

Benchmark.put_prots(:one_ip)
one_ip = Benchmark.mesure_run(time)

Benchmark.put_prots(:a10_ips)
a10_ips = Benchmark.mesure_run(time)

Benchmark.put_prots(:one_path)
one_path = Benchmark.mesure_run(time)

Benchmark.put_prots(:a500_paths)
a500_paths = Benchmark.mesure_run(time)


Benchmark.flush_prots()


IO.puts(one_ip)
IO.puts(a10_ips)
IO.puts(one_path)
IO.puts(a500_paths)
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
