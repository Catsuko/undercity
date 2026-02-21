defmodule UndercityServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :undercity_server,
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger, :wx, :observer, :runtime_tools],
      mod: {UndercityServer.Application, []}
    ]
  end

  defp deps do
    [
      {:undercity_core, in_umbrella: true}
    ]
  end
end
