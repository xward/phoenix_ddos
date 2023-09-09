defmodule PhoenixDDOS.MixProject do
  use Mix.Project

  @version "0.7.0"

  def project do
    [
      app: :phoenix_ddos,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {PhoenixDDOS.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.14"},
      {:cachex, "~> 3.6"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:test, :dev], runtime: false}
    ]
  end

  defp aliases do
    [
      release: [
        "cmd git tag v#{@version}",
        "cmd git push",
        "cmd git push --tags",
        "hex.publish package --yes",
        "hex.build"
      ],
      "test.ci": [
        "format --check-formatted",
        "deps.unlock --check-unused",
        "credo --strict",
        "test --raise"
      ]
    ]
  end
end
