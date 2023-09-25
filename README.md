# PhoenixDDoS

High performance application-layer DDoS protection for Elixir Phoenix.


<p align="center">
  <a href="https://hexdocs.pm/phoenix_ddos/PhoenixDDoS.html">
    <img alt="Hex Docs" src="http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat">
  </a>
  <a href="https://github.com/xward/phoenix_ddos/actions/workflows/ci.yml">
    <img alt="CI Status" src="https://github.com/xward/phoenix_ddos/actions/workflows/ci.yml/badge.svg">
  </a>
  <a href="https://hex.pm/packages/phoenix_ddos">
    <img alt="Hex Version" src="https://img.shields.io/hexpm/v/phoenix_ddos.svg">
  </a>
  <a href="https://opensource.org/licenses/Apache-2.0">
    <img alt="Apache 2 License" src="https://img.shields.io/hexpm/l/phoenix_ddos">
  </a>
</p>

# Table of contents

- [Features](#features)
- [Setup](#installation)
  - [Installation](#installation)
  - [Configuration](#configuration)
- [Monitoring]()
  - [Telemetry events]()
  - [Sentry]()
- [Local tooling]()
  - DDoS youself using siege (mix phoenix_ddos.attack_myself)
- [Benchmark](https://github.com/xward/phoenix_ddos/blob/master/docs/benchmark.md)
- [Community](#community)
- [Next in roadmap](#next-in-roadmap)
- [Contributing](#contributing)


Telemetry events (@see module PhoenixDDoS.Telemetry)
Notification to sentry
How it works (you defined rules and list, it can put in jail or just block if it reach any threshold)

# Features

- protection: ip safelist_ips
- protection: ip blocklist_ips
- protection: `PhoenixDDoS.IpRateLimit`
- protection: `PhoenixDDoS.IpRateLimitPerRequestPath`
- protection: log flooding
- engine: jail system
- monitoring: telemetry
- monitoring: sentry
- local tools: ddos youself testing

# Usage
<!-- MDOC -->

`phoenix_ddos` is a high performance application-layer DDoS protection for Elixir Phoenix.

## Installation

1. Add `:phoenix_ddos` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_ddos, "~> 0.7"},
    # Highly recommended, this will makes sure we get the correct remote_ip
    {:remote_ip, "~> 1.1"}
  ]
end
```

2. Add the `PhoenixDDoS` plug to your app's Endpoint, after the excellent [RemoteIp][remote_ip_github] plug (optional but highly recommended !).

```elixir
defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  # put as high in the order as possible
  plug RemoteIp
  plug PhoenixDDoS

  # ...

end
```

## Configuration

```elixir
config :phoenix_ddos,
  safelist_ips: ["1.2.3.4", "5.6.7.0"],
  blocklist_ips: ["11.12.13.0"],
  protections: [
    # ip rate limit
    {PhoenixDDoS.IpRateLimit, allowed: 500, period: {2, :minutes}},
    {PhoenixDDoS.IpRateLimit, allowed: 10_000, period: {1, :hour}},
    # ip rate limit on specific request_path
    {PhoenixDDoS.IpRateLimitPerRequestPath,
     request_paths: ["/graphql"], allowed: 20, period: {1, :minute}}
  ]
```

| Type | Option                    | Default | Description                                                                                     |
| :--- | :------------------------ | :------ | :---------------------------------------------------------------------------------------------- |
| bool | `enabled`                 | true    | set false to disable                                                                            |
| int  | `jail_time` (minutes)     | 15      | time an ip is fully blocked if caught by a protection. set nil to disable thus blocking instead |
| bool | `raise_on_reject`         | false   | raise when we reject a connexion instead of returning an http code error                        |
| int  | `http_code_on_reject`     | 429     | http code returned when we reject a connexion                                                   |
| list | `protections`             |         | @see [Protections examples][protection_examples]                                                |
| list | `safelist_ips`            |         | bypass all protections ips                                                                      |
| list | `blocklist_ips`           |         | always blocked ips                                                                              |
| bool | `on_jail_alert_to_sentry` | false   | notify slack when an ip get jailed                                                              |


[protection_examples]: #examples-with-protection-phoenixddosipratelimit


### Examples with protection `PhoenixDDoS.IpRateLimit`

1. 500 per minute max, if triggered ip will be in jail for 15 minutes
```elixir
  [{PhoenixDDoS.IpRateLimit, allowed: 500, period: {1, :minute}}]
```

2. disable jail, ip will be throttle to 500 per minute
```elixir
  [{PhoenixDDoS.IpRateLimit, allowed: 500, period: {1, :minute}, jail_time: nil}]
```

### Examples with protection `PhoenixDDoS.IpRateLimitPerRequestPath`

1. single route /graphql with a 20 per minute max, if triggered ip will be in jail for 15 minutes
```elixir
    [{PhoenixDDoS.IpRateLimitPerRequestPath,
     request_paths: ["/graphql"], allowed: 20, period: {1, :minute}}]
```

2. you can also give a phoenix-like path
```elixir
    [{PhoenixDDoS.IpRateLimitPerRequestPath,
     request_paths: ["/admin/:id/dashboard"], allowed: 20, period: {1, :minute}}]
```

3. multiple route consumming same quota
```elixir
    [{PhoenixDDoS.IpRateLimitPerRequestPath,
     request_paths: ["/graphql", "/graphiql"], allowed: 20, shared: true, period: {1, :minute}}]
```

4. multiple route consumming independant quota
```elixir
    [{PhoenixDDoS.IpRateLimitPerRequestPath,
     request_paths: ["/graphql", "/graphiql"], allowed: 20, period: {1, :minute}}]
```

is equivalant to:
```elixir
  [
   {PhoenixDDoS.IpRateLimitPerRequestPath,
    request_paths: ["/graphql"], allowed: 20, period: {1, :minute}},
   {PhoenixDDoS.IpRateLimitPerRequestPath,
    request_paths: ["/graphiql"], allowed: 20, period: {1, :minute}}
  ]
```

[remote_ip_github]: https://github.com/ajvondrak/remote_ip


## Community

Slack: join [elixir-lang](https://elixir-lang.slack.com/) and join channel `#phoenix_ddos`


## Next in roadmap

- release a v1
- ip blocklist/safelist with mask/subnet
- log central genserver to avoid log spam and create possibility provide aggregated report
- more performances
- out of jail system: an attacker ip would go out of jail and will make some damage again before being put in jail, prevent that


## contributing

[Create issues](https://github.com/xward/phoenix_ddos/issues) on github for any bug or issue.

To contribute on the code, please clone and use following tools:

run tests
```
mix test
```

run release code validation
```
mix ci
```
