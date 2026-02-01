defmodule Mix.Tasks.Undercity.Server do
  use Mix.Task

  @moduledoc false
  @shortdoc "Start the Undercity game server"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [name: :string])
    name = opts[:name] || "default"

    Application.ensure_all_started(:undercity_core)

    {:ok, _pid} = UndercityCore.Server.start_link(name: name)

    Mix.shell().info("Server #{name} started")
    Process.sleep(:infinity)
  end
end
