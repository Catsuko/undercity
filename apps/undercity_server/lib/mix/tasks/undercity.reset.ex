defmodule Mix.Tasks.Undercity.Reset do
  @shortdoc "Clear all persisted undercity data"

  @moduledoc """
  Mix task that wipes all persisted game data from disk.

  - Deletes the `data/blocks/` directory and its contents
  - Deletes the `data/players/` directory and its contents
  - Intended for development resets; use with caution in shared environments
  """
  use Mix.Task

  @doc """
  Removes the block and player data directories relative to the current working directory.
  """
  def run(_args) do
    data_dir = File.cwd!()
    File.rm_rf!(Path.join(data_dir, "data/blocks"))
    File.rm_rf!(Path.join(data_dir, "data/players"))
    IO.puts("Undercity data cleared.")
  end
end
