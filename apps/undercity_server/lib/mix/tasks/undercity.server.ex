defmodule Mix.Tasks.Undercity.Server do
  use Mix.Task

  @moduledoc false
  @shortdoc "Start the Undercity game server"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [name: :string])
    name = opts[:name] || "default"

    Mix.Task.run("app.start")

    {:ok, _pid} = UndercityServer.GameServer.start_link(name: name)

    Mix.shell().info("Server #{name} started")
    Process.sleep(:infinity)
  end
end
