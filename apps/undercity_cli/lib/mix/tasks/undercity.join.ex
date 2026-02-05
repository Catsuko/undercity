defmodule Mix.Tasks.Undercity.Join do
  use Mix.Task

  alias UndercityCli.Spinner

  @moduledoc false
  @shortdoc "Join an Undercity game server"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [server: :string, player: :string])
    server = opts[:server] || "default"
    player = opts[:player] || "anonymous"

    Spinner.start()

    case UndercityServer.GameServer.connect(server, player) do
      {:ok, name} ->
        Spinner.success("Connected to #{name} as #{player}")

      {:error, :server_not_found} ->
        Spinner.failure("Could not reach the undercity")

        Mix.raise(
          "Could not find server \"#{server}\". Is the server running with --name #{server}?"
        )

      {:error, :server_down} ->
        Spinner.failure("The undercity has gone dark")
        Mix.raise("Server node is down")
    end
  end
end
