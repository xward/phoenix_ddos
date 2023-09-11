# PhoenixDDoS

High performance application-layer DDoS protection for Elixir Phoenix.

> :warning: The project was created very recently, gimme time to bring it to a well documented v1 !

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


# Features

ip whitelist

ip blacklist

`PhoenixDDoS.IpRateLimit`

`PhoenixDDoS.IpRateLimitPerRequestPath`


# Installation

Add `:phoenix_ddos` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_ddos, "~> 0.7"},
    # Highly recommended, this will makes sure we get the correct remote_ip
    {:remote_ip, "~> 1.1"}
  ]
end
```

# Usage

Add the `PhoenixDDoS` plug to your app's Endpoint, after the excellent [RemoteIp][remote_ip_github] plug (optional but highly recommended !).

```elixir
defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  # ...

  plug RemoteIp
  plug PhoenixDDoS

  # ...

end
```

# Configuration

```elixir
config :phoenix_ddos,
  safelist_ips: ["1.2,3,4", "5.6.7.0"],
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

| Type | Option                 | Default | Description                                                               |
| :--- | :--------------------- | :------ | :------------------------------------------------------------------------ |
| bool | `enabled`              | true    | set false to disable                                                      |
| int  | `jail_time` (minutes)  | 15      | time an ip is fully blocked if caught by a protection. set nil to disable |
| bool | `raise_on_reject`      | false   | raise when we reject a connexion instead of returning an http code error  |
| int  | `http_code_on_reject`  | 429     | http code returned when we reject a connexion                             |
| list | `protections`          |         | @see Protections                                                          |
| list | `safelist_ips`         |         | bypass all protections ips                                                |
| list | `blocklist_ips`        |         | always blocked ips                                                        |

## Ip jail

All protections that trigger a deny of an ip will push said ip into jail.

Jail time ca be configured or disabled globally on per protection.

# Motivation

Add layer of protection within your phoenix application. Multi-layered DDoS protection is the best protection !

Nothing exist in Elixir ecosytem, let's create it !

you don't always have access to a ddos protection in between internet and your phoenix application
You want advance ddos feature you can't have outside an applicative environment

inspiration: [rack-attack][rack-attack_github]

# Protections

## Examples with `PhoenixDDoS.IpRateLimit`

1. 500 per minute max, if triggered ip will be in jail for 15 minutes
```elixir
  [{PhoenixDDoS.IpRateLimit, allowed: 500, period: {1, :minute}}]
```

2. disable jail, ip will only be throttle to 500 per minute
```elixir
  [{PhoenixDDoS.IpRateLimit, allowed: 500, period: {1, :minute}, jail_time: nil}]
```

## Examples with `PhoenixDDoS.IpRateLimitPerRequestPath`

1. single route
```elixir
    [{PhoenixDDoS.IpRateLimitPerRequestPath,
     request_paths: ["/graphql"], allowed: 20, period: {1, :minute}}]
```

2. multiple route consumming same quota
```elixir
    [{PhoenixDDoS.IpRateLimitPerRequestPath,
     request_paths: ["/graphql", "/graphiql"], allowed: 20, shared: true, period: {1, :minute}}]
```

3. multiple route consumming independant quota
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
[rack-attack_github]: https://github.com/ajvondrak/remote_ip
