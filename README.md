# PhoenixDDOS


## Installation

Add `:phoenix_ddos` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:phoenix_ddos, "~> 0.7"}]
end
```

## Usage

Add the `PhoenixDDOS` plug to your app's plug pipeline:

```elixir
defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  # ...

  plug PhoenixDDOS

  # ...

end
```


## Motivation

add a layer of protection within your phoenix application

you don't always have access to a ddos protection in between internet and your phoenix application
You want advance ddos feature you can't have outside an applicative environment


## Configuration
