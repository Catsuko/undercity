defmodule Mix.Tasks.Undercity.Reset do
  use Mix.Task

  @moduledoc false
  @shortdoc "Clear all persisted undercity data"

  def run(_args) do
    UndercityServer.Store.start()
    UndercityServer.Store.clear()
    UndercityServer.Store.stop()
    IO.puts("Undercity data cleared.")
  end
end
