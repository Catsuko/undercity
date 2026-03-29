defmodule Mix.Tasks.Undercity.Server do
  @shortdoc "Start the Undercity game server"

  @moduledoc """
  Starts the Undercity game server and blocks until the process is killed.

  - Boots the application via `mix app.start`
  - Runs as a named Erlang node (`undercity_server@127.0.0.1`)
  - Use `mix undercity.reset` to clear persisted data before starting fresh
  """

  use Mix.Task

  require Logger

  @doc """
  Starts the application and sleeps indefinitely, keeping the server alive.
  """
  def run(_args) do
    Mix.Task.run("app.start")

    Logger.info("Server started")
    Process.sleep(:infinity)
  end
end
