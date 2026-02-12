defmodule Mix.Tasks.Undercity.Reset do
  @shortdoc "Clear all persisted undercity data"

  @moduledoc false
  use Mix.Task

  def run(_args) do
    data_dir = File.cwd!()
    File.rm_rf!(Path.join(data_dir, "data/blocks"))
    File.rm_rf!(Path.join(data_dir, "data/players"))
    IO.puts("Undercity data cleared.")
  end
end
