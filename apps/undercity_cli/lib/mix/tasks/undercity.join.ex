defmodule Mix.Tasks.Undercity.Join do
  use Mix.Task

  @moduledoc false
  @shortdoc "Join an Undercity game server"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [server: :string, player: :string])
    server = opts[:server] || "default"
    player = opts[:player] || "anonymous"

    unless Node.connect(UndercityCore.server_node()) do
      Mix.raise("Could not connect to server. Is it running?")
    end

    case :rpc.call(UndercityCore.server_node(), UndercityCore.Server, :connect, [server, player]) do
      {:ok, name} ->
        Mix.shell().info("Connected to #{name} as #{player}")

      {:error, :server_not_found} ->
        Mix.raise("Server \"#{server}\" not found. Is the server running with --name #{server}?")
    end
  end
end
