defmodule Mix.Tasks.Undercity.Reset do
  use Mix.Task

  @moduledoc false
  @shortdoc "Clear all persisted undercity data"

  def run(_args) do
    data_dir = Path.join(File.cwd!(), "data/blocks")
    File.rm_rf!(data_dir)
    IO.puts("Undercity data cleared.")
  end
end
