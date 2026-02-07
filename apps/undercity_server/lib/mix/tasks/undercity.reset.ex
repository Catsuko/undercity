defmodule Mix.Tasks.Undercity.Reset do
  @shortdoc "Clear all persisted undercity data"

  @moduledoc false
  use Mix.Task

  def run(_args) do
    data_dir = Path.join(File.cwd!(), "data/blocks")
    File.rm_rf!(data_dir)
    IO.puts("Undercity data cleared.")
  end
end
