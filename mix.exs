defmodule Buildable.MixProject do
  use Mix.Project

  def project do
    [
      app: :buildable,
      aliases: aliases(),
      version: "0.1.0-dev",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      preferred_cli_env: ["test.all": :test],
      test_coverage: [tool: Coverex.Task],
      dialyzer: [ignore_warnings: "dialyzer.ignore-warnings"],
      docs:
        if Mix.env() == :test do
          docs() |> Keyword.put(:output, "tmp/doc")
        else
          docs()
        end
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
      {:benchee, "~> 1.0", only: :dev},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.26", only: [:dev, :test], runtime: false},
      {:coverex, "~> 1.5", only: :test}
    ]
  end

  # Helpers
  defp elixirc_paths(:test), do: ["lib", "test/protocols"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      "test.all": ["compile --warnings-as-errors", "lint", "docs", "dialyzer", "test"],
      lint: ["format --check-formatted", "credo"]
    ]
  end

  defp docs do
    [
      main: "Buildable",
      groups_for_modules: [
        Protocols: [
          Buildable,
          Buildable.Behaviour,
          Buildable.Collectable,
          Buildable.Reducible
        ],
        Convenience: [
          Buildable.Delegation,
          Buildable.Implementation
        ]
      ]
    ]
  end
end
