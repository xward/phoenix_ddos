defmodule PhoenixDDoS.MixProject do
  use Mix.Project

  @version "1.1.16"
  @source_url "https://github.com/xward/phoenix_ddos"

  def project do
    [
      app: :phoenix_ddos,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: [
        benchmark: :test,
        credo: :test,
        ci: :test
      ],
      # hex
      package: [
        maintainers: ["xward"],
        licenses: ["Apache-2.0"],
        files: ~w(lib .formatter.exs mix.exs README* CHANGELOG* LICENSE*),
        links: %{
          Changelog: "#{@source_url}/blob/master/CHANGELOG.md",
          GitHub: @source_url
        }
      ],
      description: """
      High performance application-layer DDoS protection for Elixir Phoenix
      """,
      # Dialyzer
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix],
        plt_core_path: "_build/#{Mix.env()}",
        flags: [:error_handling, :missing_return, :underspecs]
      ],
      # Docs
      name: "PhoenixDDoS",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: [
        # The main page in the docs
        main: "PhoenixDDoS",
        source_ref: "v#{@version}",
        source_url: @source_url,
        # logo: "path/to/logo.png",
        extra_section: "GUIDES",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {PhoenixDDoS.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support", "benchmark"]
  defp elixirc_paths(:dev), do: ["lib", "test/support/router.ex"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.14"},
      {:cachex, ">= 3.0.0"},
      {:telemetry, ">= 0.0.0"},
      {:phoenix, "~> 1.7", only: [:test, :dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:test, :dev], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:test, :dev], runtime: false}
    ]
  end

  defp aliases do
    [
      benchmark: "run benchmark/benchmark.exs",
      credo: "credo --strict",
      ci: [
        # clean previous compiled .eex files
        "clean",
        "format --check-formatted",
        "deps.unlock --check-unused",
        "credo --strict",
        "test --raise",
        "dialyzer"
      ],
      release: [
        "cmd git tag v#{@version}",
        "cmd git push origin master",
        "cmd git push --tags",
        "hex.publish --yes",
        "cmd rm -rf doc"
      ]
    ]
  end
end
