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
      {:ok, block_name} ->
        Spinner.success("Connected to #{server} as #{player} (#{block_name})")

      {:error, :server_not_found} ->
        Spinner.failure("Could not reach the server")

      {:error, :server_down} ->
        Spinner.failure("Could not reach the server")
    end
  end
end
