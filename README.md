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
- Setup
  - [Installation](#installation)
  - [Configuration](#configuration)
- Monitoring
  - [Telemetry events](https://hexdocs.pm/phoenix_ddos/PhoenixDDoS.Telemetry.html)
  - [Sentry](#configuration)
- Local tooling
  - [DDoS yourself using siege (mix phoenix_ddos.attack_myself)](https://hexdocs.pm/phoenix_ddos/Mix.Tasks.PhoenixDdos.AttackMyself.html)
- [Benchmark](https://github.com/xward/phoenix_ddos/blob/master/docs/benchmark.md)
- [Community](#community)
- [FAQ](#faq)
  - [Why would I need this compared to a system like cloudflare or a reverse proxy with a fail2ban ?](#why-would-i-need-this-compared-to-a-system-like-cloudflare-or-a-reverse-proxy-with-a-fail2ban-)
  - [What is a multi-layer ddos protection and why this is important ?](#what-is-a-multi-layer-ddos-protection-and-why-this-is-important-)
- [Next in roadmap](#next-in-roadmap)
- [Later in roadmap](#later-in-roadmap)
- [Contributing](#contributing)

---

> **Note**
> _You are currently on unreleased branch. Latest stable release documentation is [here][hexdoc]_

[hexdoc]: https://hexdocs.pm/phoenix_ddos/PhoenixDDoS.html

---

# Features

- **protection: ip safelist_ips** - List of ip that bypass all checks
- **protection: ip blocklist_ips** - List of ip that are always rejected
- **protection: `PhoenixDDoS.IpRateLimit`** - rate limit per ip
- **protection: `PhoenixDDoS.IpRateLimitPerRequestPath`** - rate limit per ip per path
- **protection: log flooding** - in case of an attack, prevent application log to explode
- **engine: jail system** - auto-blocklist ips that triggered a protection for a limited amount of time
- **monitoring: telemetry** - provide events to your application from phoenix_ddos decisions
- **monitoring: sentry** - if you use sentry, you can be notified when an ip has been put in jail
- **local tools: ddos youself** - because it is fun !

# Usage
<!-- MDOC -->

`phoenix_ddos` is a high performance application-layer DDoS protection for Elixir Phoenix.

## Installation

1. Add `:phoenix_ddos` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_ddos, "~> 1.1"},
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
  plug RemoteIp, headers: ["x-forwarded-for"]
  plug PhoenixDDoS

  # ...

end
```

## Configuration

```elixir
config :phoenix_ddos,
  router: MyAppWeb.Router,
  safelist_ips: ["1.2.3.4", "5.6.7.0"],
  blocklist_ips: ["11.12.13.0"],
  observer: true,
  protections: [
    # ip rate limit
    {PhoenixDDoS.IpRateLimit, allowed: 500, period: {2, :minutes}},
    {PhoenixDDoS.IpRateLimit, allowed: 10_000, period: {1, :hour}},
    # ip rate limit on specific request_path
    {PhoenixDDoS.IpRateLimitPerRequestPath,
     request_paths: ["/graphql"], allowed: 20, period: {1, :minute}},
    {PhoenixDDoS.IpRateLimitPerRequestPath,
     request_paths: [{:post, "/login"}], allowed: 5, period: {30, :seconds}}
  ]
```

| Type | Option                    | Default       | Description                                                                                     |
| :--- | :------------------------ | :------------ | :---------------------------------------------------------------------------------------------- |
| atom | `router`                  | <mandatory>   | your phoenix web router                                                                         |
| bool | `enabled`                 | true          | set false to disable                                                                            |
| int  | `jail_time`               | {15, minutes} | time an ip is fully blocked if caught by a protection. set nil to disable thus blocking instead |
| bool | `raise_on_reject`         | false         | raise when we reject a connexion instead of returning an http code error                        |
| int  | `http_code_on_reject`     | 429           | http code returned when we reject a connexion                                                   |
| list | `protections`             | []            | @see [Protections examples][protection_examples]                                                |
| list | `safelist_ips`            | []            | bypass all protections ips                                                                      |
| list | `blocklist_ips`           | []            | always blocked ips                                                                              |
| bool | `on_jail_alert_to_sentry` | false         | notify slack when an ip get jailed                                                              |


[protection_examples]: #examples-with-protection-phoenixddosipratelimit

> The configuration is per node you run, rate_limits are not shared (yet), but it gives you the best performance in case of an attack.

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

3. you can also specify method
```elixir
    [
      {PhoenixDDoS.IpRateLimitPerRequestPath,
     request_paths: [{:post, "/login"}, {:post, "/logout"}], allowed: 5, period: {1, :minute}},
      {PhoenixDDoS.IpRateLimitPerRequestPath,
     request_paths: [{:get, "/login"}], allowed: 100, period: {5, :minute}}
    ]
```

4. multiple route consuming same quota
```elixir
    [{PhoenixDDoS.IpRateLimitPerRequestPath,
     request_paths: ["/graphql", "/graphiql"], allowed: 20, shared: true, period: {1, :minute}}]
```

5. multiple route consuming independent quota
```elixir
    [{PhoenixDDoS.IpRateLimitPerRequestPath,
     request_paths: ["/graphql", "/graphiql"], allowed: 20, period: {1, :minute}}]
```

is equivalent to:
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

## FAQ

### Why would I need this compared to a system like cloudflare or a reverse proxy with a fail2ban ?

The best ddos protection is like any protection: you have to have multiple layers of protection, each layer having its own advantage or disadvantage. In that matter, to maximize protection you should use one system per layer.

Also we have to keep in mind that a lot of projects don't have the capability (running in a PaaS like heroku for instance) or the will to have all these systems in place. Since `phoenix_ddos` is a plug-and-play (pun intended) library with minimum configuration, it is a great value for a minimum of effort.

### What is a multi-layer ddos protection and why this is important ?

`phoenix_ddos` is the application layer, running in the application itself. It advantage is that is knows the inside of the application and its limits and can act on the details, where a cloudflare or a ngnix fail2ban would manage most of the load, but the traffic that still access your application may still kill it, this is then the responsability of `phoenix_ddos`.

##### Example of a phoenix application cluster: e.g. 10 pods running each the same phoenix application:

Other layers will protect the entire cluster and `phoenix_ddos` will protect each phoenix application individually.

Since one phoenix application have its own limits, it is best to have a throttle at this layer.

If the cluster scale up or down (switching to 3 pods or 30 pods), other layers will never adapt their throttle values, but `phoenix_ddos` will scale its protection gracefully.

##### Comparaison with an home electrical installation:

In home installation, you have 2 layers of protection doing the exact same thing:
- one differential switch protecting the house globally, with a **small sensitivity**, this will protect the house from burning if a bad short circuit happen
- several differential switches in the electric switchboard, with **high sensitivity**, this will protect people from being badly injured in case of a shock. We can note that those switches are `application specialized` because they are chosen according to the load they have to protect, something the other layer can't manage since it has no idea of the house usage in detail.

## Next in roadmap

- [monitoring] observe tooling, to be able to observe what volume is normal traffic and craft a configuration accordingly
- [feat] ip blocklist/safelist with mask/subnet
- [feat] log central genserver to avoid log spam and create possibility provide aggregated report
- [feat] out of jail system: an attacker ip would go out of jail and will make some damage again before being put in jail, prevent that

## Later in roadmap

- [feat] multi-node
- [path] make a phoenix_ddos_pro with powerful features for companies ? The oban model might be a good path to take !

## Contributing

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
