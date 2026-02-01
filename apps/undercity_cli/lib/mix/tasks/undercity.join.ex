defmodule Mix.Tasks.Undercity.Join do
  use Mix.Task

  @moduledoc false
  @shortdoc "Join an Undercity game server"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [server: :string, player: :string])
    server = opts[:server] || "default"
    _player = opts[:player] || "anonymous"

    unless Node.alive?() do
      Mix.raise(
        "This task must be run as a distributed node.\n\n" <>
          "  elixir --name client_#{:rand.uniform(10000)}@127.0.0.1 -S mix undercity.join --server #{server}"
      )
    end

    true = Node.connect(:"undercity_server@127.0.0.1")

    {:ok, name} =
      :rpc.call(:"undercity_server@127.0.0.1", UndercityCore.Server, :connect, [server])

    Mix.shell().info("Connected to #{name}")
  end
end
