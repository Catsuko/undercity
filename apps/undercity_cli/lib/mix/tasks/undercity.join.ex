defmodule Mix.Tasks.Undercity.Join do
  use Mix.Task

  @moduledoc false
  @shortdoc "Join an Undercity game server"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [server: :string, player: :string])
    server = opts[:server] || "default"
    player = opts[:player] || "anonymous"
    Mix.shell().info("TODO: connect to #{server} as #{player}")
  end
end
