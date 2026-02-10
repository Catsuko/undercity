defmodule UndercityServer do
  @moduledoc false

  def server_node do
    if Node.alive?(), do: :"undercity_server@127.0.0.1", else: node()
  end
end
