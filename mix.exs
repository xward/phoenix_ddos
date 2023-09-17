defmodule PhoenixDDoS.MixProject do
  use Mix.Project

  @version "0.7.18"
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
        extras: ["README.md"],
        groups_for_modules: groups_for_modules()
      ]
    ]
  end

  defp groups_for_modules do
    [
      Protections: [
        PhoenixDDoS.IpRateLimit,
        PhoenixDDoS.IpRateLimitPerRequestPath
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
      {:telemetry, "~> 1.2"},
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
        "hex.publish --yes",
        "hex.build",
        "cmd rm phoenix_ddos-*.tar",
        "cmd rm -rf doc"
      ]
    ]
  end
end
