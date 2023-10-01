## Benchmark

Using `mix benchmark`, we try different phoenix_ddos configurations:

| Configuration             | Speed                        |
| :------------------------ | :--------------------------- |
|         1 ip 1 rate limit |     33 ms per 10_000 queries |
|     10 ips 10 rate limits |    113 ms per 10_000 queries |
|   500 ips 500 rate limits |   4716 ms per 10_000 queries |
|       1 path 1 rate limit |     14 ms per 10_000 queries |
|    500 paths 1 rate limit |     14 ms per 10_000 queries |
|          1 safelisted ip  |     14 ms per 10_000 queries |
|        500 safelisted ips |     42 ms per 10_000 queries |
|         1 blocklisted ip  |     44 ms per 10_000 queries |
|       500 blocklisted ips |     68 ms per 10_000 queries |

Comparaison with previous versions:

| Configuration             | Speed (v0.7.18)              |
| :------------------------ | :--------------------------- |
|         1 ip 1 rate limit |     38 ms per 10_000 queries |
|     10 ips 10 rate limits |    148 ms per 10_000 queries |
|   500 ips 500 rate limits |   5110 ms per 10_000 queries |
|       1 path 1 rate limit |     25 ms per 10_000 queries |
|    500 paths 1 rate limit |   2450 ms per 10_000 queries |
|          1 safelisted ip  |                            - |
|        500 safelisted ips |                            - |
|         1 blocklisted ip  |                            - |
|       500 blocklisted ips |                            - |


running on 1 thread on a i9-9900k NOC

## why performance matters ?

One one hand it is sweet to have this plug running fast since a query will go through on every requests. Being simple and predicatble is as much important.

What phoenix_ddos we aim for is being able to be as efficient as possible when an attack actually occures.
