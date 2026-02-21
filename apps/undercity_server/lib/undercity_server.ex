defmodule UndercityServer do
  @moduledoc false

  def server_node do
    if Node.alive?(), do: :"undercity_server@127.0.0.1", else: node()
  end

  def data_dir do
    Application.get_env(:undercity_server, :data_dir, "data")
  end
end
