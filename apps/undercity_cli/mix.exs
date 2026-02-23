defmodule UndercityCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :undercity_cli,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:owl, "~> 0.13.0"},
      {:undercity_server, in_umbrella: true},
      {:mimic, "~> 2.0", only: :test}
    ]
  end
end
