defmodule Watts.MixProject do
  use Mix.Project

  def project do
    [
      app: :watts,
      version: "0.1.0",
      elixir: "~> 1.20",
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
      # `certifi` is transitively required by `ex_aws` -> `hackney`. Override it in response to
      # the eMudhra CA compromise. If/when either of the two dependencies are upgraded to use
      # `certifi@2.18.0+`, we can remove this.
      {:certifi, "2.18.0", override: true},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:lcov_ex, "~> 0.3", only: [:dev, :test], runtime: false},
      {:bandit, "~> 1.0"},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:ex_aws_polly, "~> 0.5"},
      {:hackney, "~> 1.20"},
      {:mox, "~> 1.2", only: [:test]}
    ]
  end
end
