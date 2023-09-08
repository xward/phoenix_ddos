defmodule PhoenixDdos.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_ddos,
      version: "0.7.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.14"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
