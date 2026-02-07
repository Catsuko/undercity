defmodule Mix.Tasks.Undercity.Join do
  @shortdoc "Join an Undercity game server"

  @moduledoc false
  use Mix.Task

  alias UndercityCli.GameLoop
  alias UndercityCli.Spinner
  alias UndercityCli.View

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [server: :string, player: :string])
    server = opts[:server] || "default"
    player = opts[:player] || "anonymous"

    Spinner.start()

    case UndercityServer.GameServer.connect(server, player) do
      {:ok, block_info} ->
        Spinner.success("Woke up in #{block_info.name} as #{player}")
        Spinner.dismiss()
        IO.puts(View.describe_block(block_info, player))
        GameLoop.run(server, player, block_info)

      {:error, :server_not_found} ->
        Spinner.failure("Could not reach the server")

      {:error, :server_down} ->
        Spinner.failure("Could not reach the server")
    end
  end
end
