# PhoenixDDOS


## Installation

Add `:phoenix_ddos` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_ddos, "~> 0.7"},
    # Highly recommanded, this will makes sure we get the correct remote_ip in Conn
    {:remote_ip, "~> 1.1"}
  ]
end
```

## Usage

Add the `PhoenixDDOS` plug to your app's plug pipeline, along with the amazing `RemoteIp` (optional but highly recommanded !)


```elixir
defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  # ...

  plug RemoteIp
  plug PhoenixDDOS

  # ...

end
```


## Motivation

add a layer of protection within your phoenix application

you don't always have access to a ddos protection in between internet and your phoenix application
You want advance ddos feature you can't have outside an applicative environment


## Configuration
