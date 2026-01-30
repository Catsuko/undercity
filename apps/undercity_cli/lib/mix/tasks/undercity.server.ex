defmodule Mix.Tasks.Undercity.Server do
  use Mix.Task

  @shortdoc "Start the Undercity game server"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [name: :string])
    name = opts[:name] || "default"
    Mix.shell().info("TODO: server #{name}")
  end
end
