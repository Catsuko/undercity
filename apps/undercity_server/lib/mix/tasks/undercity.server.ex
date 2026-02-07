defmodule Mix.Tasks.Undercity.Server do
  @shortdoc "Start the Undercity game server"

  @moduledoc false
  use Mix.Task

  require Logger

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [name: :string])
    name = opts[:name] || "default"

    Mix.Task.run("app.start")

    {:ok, _pid} = UndercityServer.GameServer.start_link(name: name)

    Logger.info("Server #{name} started")
    Process.sleep(:infinity)
  end
end
