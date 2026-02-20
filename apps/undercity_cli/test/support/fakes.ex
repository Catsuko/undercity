defmodule FakeGateway do
  @moduledoc false
  def perform(_player_id, _block_id, :move, _direction), do: {:ok, {:ok, %{id: "dest_block"}}, 9}
  def perform(_player_id, _block_id, :search, _), do: {:ok, :nothing, 9}
  def perform(_player_id, _block_id, :eat, _index), do: {:error, :invalid_index}
  def perform(_player_id, _block_id, :scribble, _text), do: {:error, :item_missing}
  def check_inventory(_player_id), do: []
  def drop_item(_player_id, _index), do: {:ok, "Sword", 9}
end

defmodule ExhaustedGateway do
  @moduledoc false
  def perform(_player_id, _block_id, _action, _args), do: {:error, :exhausted}
  def drop_item(_player_id, _index), do: {:error, :exhausted}
end

defmodule CollapsedGateway do
  @moduledoc false
  def perform(_player_id, _block_id, _action, _args), do: {:error, :collapsed}
  def drop_item(_player_id, _index), do: {:error, :collapsed}
end

defmodule FakeMessageBuffer do
  @moduledoc false
  def warn(msg), do: send(self(), {:warn, msg})
  def info(msg), do: send(self(), {:info, msg})
  def success(msg), do: send(self(), {:success, msg})
end
