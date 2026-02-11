defmodule Mix.Tasks.Undercity.Join do
  @shortdoc "Join an Undercity game server"

  @moduledoc false
  use Mix.Task

  alias UndercityCli.GameLoop
  alias UndercityCli.Spinner
  alias UndercityServer.Vicinity

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [player: :string])
    player = opts[:player] || "anonymous"

    Spinner.start()

    case UndercityServer.Gateway.connect(player) do
      {:ok, vicinity} ->
        Spinner.success("Woke up in #{Vicinity.name(vicinity)} as #{player}")
        Spinner.dismiss()
        GameLoop.run(player, vicinity)

      {:error, :server_not_found} ->
        Spinner.failure("Could not reach the server")

      {:error, :server_down} ->
        Spinner.failure("Could not reach the server")
    end
  end
end
