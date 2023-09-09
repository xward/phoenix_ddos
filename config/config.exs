# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

config :phoenix_ddos,
  enable: true,
  raise_on_reject: false,
  http_code_on_reject: 421,
  protections: []
