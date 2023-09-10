# PhoenixDDOS


# Installation

Add `:phoenix_ddos` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_ddos, "~> 0.7"},
    # Highly recommended, this will makes sure we get the correct remote_ip in Conn
    {:remote_ip, "~> 1.1"}
  ]
end
```

# Usage

Add the `PhoenixDDOS` plug to your app's plug pipeline, along with the excelent `RemoteIp` (optional but highly recommended !).


```elixir
defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  # ...

  plug RemoteIp
  plug PhoenixDDOS

  # ...

end
```

# Configuration

> [!WARNING]
> :warning: All configurations must be provide at compilation, you can't use runtime.exs to configure.

```elixir
config :phoenix_ddos,
  protections: [
    # ip rate limit
    {PhoenixDDOS.IpRateLimit, allowed: 500, period: {1, :minute}},
    # ip rate limit on specific request_path
    {PhoenixDDOS.IpRateLimitPerRequestPath,
     request_paths: ["/graphql"], allowed: 20, period: {1, :minute}}
  ]
```

| Option               | Default                | Description                                                               |
| :------------------- | :--------------------- | :------------------------------------------------------------------------ |
| enable               |      true   (@compil)  | set to false to disable                                                   |
| jail_time_minutes    |      5      (@compil)  | time an ip is fully blocked if caught by a protection                     |
| raise_on_reject      |     false              | raise when we reject a connexion intead of returning an http code error   |
| http_code_on_reject  |       429              | http code returned when we reject a connexion                             |
| protections          | mandatory              | @see protections configuration                                            |


# Motivation

Add layer of protection within your phoenix application. Multi-layered DDoS protection is the best protection !

you don't always have access to a ddos protection in between internet and your phoenix application
You want advance ddos feature you can't have outside an applicative environment



# Protections configuration


## Ip jail

All protections that trigger a deny of an ip will push said ip into jail.
Jail default duration is 5min, configurable.
You can also configure this time per protection, 0 is a valide configuration and disable jail mecanic from this protection.


## `PhoenixDDOS.IpRateLimit`

```elixir
  [{PhoenixDDOS.IpRateLimit, allowed: 500, period: {1, :minute}}]
```

## `PhoenixDDOS.IpRateLimitPerRequestPath`

1. single route
```elixir
    [{PhoenixDDOS.IpRateLimitPerRequestPath,
     request_paths: ["/graphql"], allowed: 20, period: {1, :minute}}]
```

2. multiple route consumming same quota
```elixir
    [{PhoenixDDOS.IpRateLimitPerRequestPath,
     request_paths: ["/graphql", "/graphiql"], allowed: 20, shared: true, period: {1, :minute}}]
```

3. multiple route consumming independant quota
```elixir
    [{PhoenixDDOS.IpRateLimitPerRequestPath,
     request_paths: ["/graphql", "/graphiql"], allowed: 20, period: {1, :minute}}]
```

4. is equivalant to:
```elixir
  [
   {PhoenixDDOS.IpRateLimitPerRequestPath,
    request_paths: ["/graphql"], allowed: 20, period: {1, :minute}},
   {PhoenixDDOS.IpRateLimitPerRequestPath,
    request_paths: ["/graphiql"], allowed: 20, period: {1, :minute}}
  ]
```

## period syntax example

period: {30, :second}
period: {1, :minute}
period: {2, :minute}
period: {1, :hour}
period: {1, :day}
