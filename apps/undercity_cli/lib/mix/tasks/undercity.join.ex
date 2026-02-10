defmodule Mix.Tasks.Undercity.Join do
  @shortdoc "Join an Undercity game server"

  @moduledoc false
  use Mix.Task

  alias UndercityCli.GameLoop
  alias UndercityCli.Spinner
  alias UndercityCli.View

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [player: :string])
    player = opts[:player] || "anonymous"

    Spinner.start()

    case UndercityServer.Gateway.connect(player) do
      {:ok, block_info} ->
        Spinner.success("Woke up in #{View.display_name(block_info)} as #{player}")
        Spinner.dismiss()
        IO.puts(View.describe_block(block_info, player))
        GameLoop.run(player, block_info)

      {:error, :server_not_found} ->
        Spinner.failure("Could not reach the server")

      {:error, :server_down} ->
        Spinner.failure("Could not reach the server")
    end
  end
end
