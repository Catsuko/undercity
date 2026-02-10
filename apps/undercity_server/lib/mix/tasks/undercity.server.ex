defmodule Mix.Tasks.Undercity.Server do
  @shortdoc "Start the Undercity game server"

  @moduledoc false
  use Mix.Task

  require Logger

  def run(_args) do
    Mix.Task.run("app.start")

    Logger.info("Server started")
    Process.sleep(:infinity)
  end
end
