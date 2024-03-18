defmodule Watts.MixProject do
  use Mix.Project

  def project do
    [
      app: :watts,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:bandit, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:aws, "~> 0.14"},
      {:hackney, "~> 1.20"}
    ]
  end
end
