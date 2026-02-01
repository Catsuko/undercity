defmodule Mix.Tasks.Undercity.Join do
  use Mix.Task

  @moduledoc false
  @shortdoc "Join an Undercity game server"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [server: :string, player: :string])
    server = opts[:server] || "default"
    player = opts[:player] || "anonymous"

    case UndercityCore.Server.connect(server, player) do
      {:ok, name} ->
        Mix.shell().info("Connected to #{name} as #{player}")

      {:error, :server_not_found} ->
        Mix.raise(
          "Could not find server \"#{server}\". Is the server running with --name #{server}?"
        )
    end
  end
end
