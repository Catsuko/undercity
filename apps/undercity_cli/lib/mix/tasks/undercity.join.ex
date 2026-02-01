defmodule Mix.Tasks.Undercity.Join do
  use Mix.Task

  @moduledoc false
  @shortdoc "Join an Undercity game server"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [server: :string, player: :string])
    server = opts[:server] || "default"
    player = opts[:player] || "anonymous"

    unless Node.alive?() do
      Mix.raise(
        "This task must be run as a distributed node.\n\n" <>
          "  elixir --name client_#{:rand.uniform(10000)}@127.0.0.1 -S mix undercity.join --server #{server}"
      )
    end

    unless Node.connect(UndercityCore.server_node()) do
      Mix.raise("Could not connect to server. Is it running?")
    end

    {:ok, name} =
      :rpc.call(UndercityCore.server_node(), UndercityCore.Server, :connect, [server, player])

    Mix.shell().info("Connected to #{name} as #{player}")
  end
end
