# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

config :phoenix_ddos,
  enable: true,
  raise_on_reject: false,
  http_code_on_reject: 421,
  protections: [
    {PhoenixDDOS.IpRateLimit, allowed: 50, period: {2, :second}},
    {PhoenixDDOS.IpRateLimit, allowed: 10_000, period: {2, :hour}},
    {PhoenixDDOS.IpRateLimitPerRequestPath,
     request_paths: ["/admin", "/user"], allowed: 3, period: {1, :minute}},
    {PhoenixDDOS.IpRateLimitPerRequestPath,
     request_paths: ["/create", "/delete"], shared: true, allowed: 3, period: {1, :minute}}
  ]
