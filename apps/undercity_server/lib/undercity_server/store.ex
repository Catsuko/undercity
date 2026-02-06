defmodule UndercityServer.Store do
  @moduledoc """
  Disk-backed persistence for undercity server state using DETS.
  """

  @table :undercity_store

  def start do
    path = data_path() |> String.to_charlist()
    File.mkdir_p!(Path.dirname(to_string(path)))
    {:ok, @table} = :dets.open_file(@table, file: path, type: :set)
    :ok
  end

  def stop do
    :dets.close(@table)
  end

  def save_block(block) do
    :ok = :dets.insert(@table, {{:block, block.id}, block})
  end

  def load_block(id) do
    case :dets.lookup(@table, {:block, id}) do
      [{_key, block}] -> {:ok, block}
      [] -> :error
    end
  end

  def clear do
    :dets.delete_all_objects(@table)
  end

  defp data_path do
    Path.join([File.cwd!(), "data", "undercity.dets"])
  end
end
