# PhoenixDDOS


## Installation

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

## Usage

Add the `PhoenixDDOS` plug to your app's plug pipeline, along with the amazing `RemoteIp` (optional but highly recommended !).


```elixir
defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  # ...

  plug RemoteIp
  plug PhoenixDDOS

  # ...

end
```

## Configuration




## Motivation

Add layer of protection within your phoenix application. Multi-layered DDoS protection is the best protection !

you don't always have access to a ddos protection in between internet and your phoenix application
You want advance ddos feature you can't have outside an applicative environment



## Configuration
