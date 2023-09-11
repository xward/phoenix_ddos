defmodule PhoenixDDoS.MixProject do
  use Mix.Project

  @version "0.7.5"
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
      [beta] Application-layer DDOS protection for phoenix.
      """,
      # Dialyzer
      dialyzer: [
        plt_add_apps: [:ex_unit],
        plt_core_path: "_build/#{Mix.env()}",
        flags: [:error_handling, :missing_return, :underspecs]
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.14"},
      {:cachex, "~> 3.6"},
      {:dialyxir, "~> 1.0", only: [:test, :dev], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:test, :dev], runtime: false}
    ]
  end

  defp aliases do
    [
      credo: "credo --strict",
      ci: [
        "format --check-formatted",
        "deps.unlock --check-unused",
        "credo --strict",
        "test --raise",
        "dialyzer"
      ],
      release: [
        "cmd git tag v#{@version}",
        "cmd git push",
        "cmd git push --tags",
        "hex.publish package --yes",
        "hex.build"
      ]
    ]
  end
end
