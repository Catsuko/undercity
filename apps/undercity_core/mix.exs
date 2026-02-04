defmodule UndercityCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :undercity_core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.19",
      deps: deps()
    ]
  end

  defp deps do
    []
  end
end
