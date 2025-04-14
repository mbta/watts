defmodule Watts.MixProject do
  use Mix.Project

  def project do
    [
      app: :watts,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: ["lib"] ++ if(Mix.env() == :test, do: ["test_support"], else: []),
      test_coverage: [tool: LcovEx]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Watts.Application, []}
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:lcov_ex, "~> 0.3", only: [:dev, :test], runtime: false},
      {:bandit, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:ex_aws_polly, "~> 0.5"},
      {:hackney, "~> 1.20"},
      {:mox, "~> 1.2", only: [:test]}
    ]
  end
end
