defmodule Tgas.MixProject do
  use Mix.Project

  def project do
    [
      app: :tgas,
      version: "0.2.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      default_release: :prod,
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Tgas.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tdlib, git: "https://github.com/lattenwald/erl-tdlib.git"},
      {:poison, "~> 5.0"},
      {:toml_config_provider, "~> 0.2.0"}
    ]
  end

  defp releases do
    [
      prod: [
        include_executables_for: [:unix],
        applications: [jsx: :permanent],
        config_providers: [
          {TomlConfigProvider, "/app/config.toml"}
        ],
        steps: [:assemble, :tar],
        path: "/app/release"
      ]
    ]
  end
end
