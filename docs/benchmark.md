## Benchmark

Using `mix benchmark`, we try different phoenix_ddos configurations:

| Configuration             | Speed                        |
| :------------------------ | :--------------------------- |
|         1 ip 1 rate limit |     32 ms per 10_000 queries |
|     10 ips 10 rate limits |     96 ms per 10_000 queries |
|   500 ips 500 rate limits |   3788 ms per 10_000 queries |
|       1 path 1 rate limit |     16 ms per 10_000 queries |
|    500 paths 1 rate limit |     16 ms per 10_000 queries |
|          1 safelisted ip  |     16 ms per 10_000 queries |
|        500 safelisted ips |     16 ms per 10_000 queries |
|         1 blocklisted ip  |     16 ms per 10_000 queries |
|       500 blocklisted ips |     16 ms per 10_000 queries |


Comparison with previous versions:

| Configuration             | Speed (v.1.10)               | Speed  (v1.1.4)              | Speed (v0.7.18)              |
| :------------------------ | :--------------------------- | :--------------------------- | :--------------------------- |
|         1 ip 1 rate limit |     33 ms per 10_000 queries |     33 ms per 10_000 queries |     38 ms per 10_000 queries |
|     10 ips 10 rate limits |    114 ms per 10_000 queries |    113 ms per 10_000 queries |    148 ms per 10_000 queries |
|   500 ips 500 rate limits |   4721 ms per 10_000 queries |   4716 ms per 10_000 queries |   5110 ms per 10_000 queries |
|       1 path 1 rate limit |     14 ms per 10_000 queries |     14 ms per 10_000 queries |     25 ms per 10_000 queries |
|    500 paths 1 rate limit |     14 ms per 10_000 queries |     14 ms per 10_000 queries |   2450 ms per 10_000 queries |
|          1 safelisted ip  |     14 ms per 10_000 queries |     14 ms per 10_000 queries |                            - |
|        500 safelisted ips |     15 ms per 10_000 queries |     42 ms per 10_000 queries |                            - |
|         1 blocklisted ip  |     14 ms per 10_000 queries |     44 ms per 10_000 queries |                            - |
|       500 blocklisted ips |     15 ms per 10_000 queries |     68 ms per 10_000 queries |                            - |


running on 1 thread on a i9-9900k NOC

## why performance matters ?

One one hand it is sweet to have this plug running fast since a query will go through on every request. Being simple and predictable is as much important.

What phoenix_ddos we aim for is being able to be as efficient as possible when an attack actually occurs.
