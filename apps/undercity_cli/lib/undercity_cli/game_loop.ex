defmodule UndercityCli.GameLoop do
  @moduledoc """
  Interactive command loop for the CLI game.
  """

  alias UndercityCli.View
  alias UndercityServer.Gateway

  @directions %{
    "north" => :north,
    "south" => :south,
    "east" => :east,
    "west" => :west,
    "n" => :north,
    "s" => :south,
    "e" => :east,
    "w" => :west,
    "enter" => :enter,
    "exit" => :exit
  }

  def run(player, player_id, vicinity, ap, hp) do
    View.render(vicinity, player)
    View.render_constitution(ap, hp)
    loop(player, player_id, vicinity, ap, hp)
  end

  defp loop(player, player_id, vicinity, ap, hp) do
    input = "> " |> IO.gets() |> String.trim() |> String.downcase()

    case dispatch(parse(input), player, player_id, vicinity, ap, hp) do
      :quit -> :ok
      {vicinity, ap, hp} -> loop(player, player_id, vicinity, ap, hp)
    end
  end

  defp dispatch(:look, player, _player_id, vicinity, ap, hp) do
    View.render(vicinity, player)
    {vicinity, ap, hp}
  end

  defp dispatch({:move, direction}, player, player_id, vicinity, ap, hp) do
    handle_move(player, player_id, vicinity, ap, hp, direction)
  end

  defp dispatch(:search, player, player_id, vicinity, ap, hp) do
    {vicinity, handle_search(player, player_id, vicinity, ap, hp), hp}
  end

  defp dispatch(:inventory, player, player_id, vicinity, ap, hp) do
    handle_inventory(player, player_id, vicinity)
    {vicinity, ap, hp}
  end

  defp dispatch({:drop, index}, player, player_id, vicinity, ap, hp) do
    {vicinity, handle_drop(player, player_id, vicinity, ap, hp, index), hp}
  end

  defp dispatch({:eat, index}, player, player_id, vicinity, ap, hp) do
    {new_ap, new_hp} = handle_eat(player, player_id, vicinity, ap, hp, index)
    {vicinity, new_ap, new_hp}
  end

  defp dispatch({:scribble, text}, player, player_id, vicinity, ap, hp) do
    {vicinity, handle_scribble(player, player_id, vicinity, ap, hp, text), hp}
  end

  defp dispatch(:quit, _player, _player_id, _vicinity, _ap, _hp), do: :quit

  defp dispatch(:unknown, player, _player_id, vicinity, ap, hp) do
    View.render_unknown_command(vicinity, player)
    {vicinity, ap, hp}
  end

  defp handle_move(player, player_id, vicinity, ap, hp, direction) do
    result = Gateway.perform(player_id, vicinity.id, :move, direction)
    View.render_move(result, vicinity, player, ap, hp)

    case result do
      {:ok, {:ok, new_vicinity}, new_ap} -> {new_vicinity, new_ap, hp}
      {:ok, {:error, :no_exit}, new_ap} -> {vicinity, new_ap, hp}
      {:error, _reason} -> {vicinity, ap, hp}
    end
  end

  defp handle_search(player, player_id, vicinity, ap, hp) do
    result = Gateway.perform(player_id, vicinity.id, :search, nil)
    View.render_search(result, vicinity, player, ap, hp)

    case result do
      {:ok, _outcome, new_ap} -> new_ap
      {:error, _reason} -> ap
    end
  end

  defp handle_drop(player, player_id, vicinity, ap, hp, index) do
    result = Gateway.drop_item(player_id, index)
    View.render_drop(result, vicinity, player, ap, hp)

    case result do
      {:ok, _item_name, new_ap} -> new_ap
      {:error, _reason} -> ap
    end
  end

  defp handle_eat(player, player_id, vicinity, ap, hp, index) do
    result = Gateway.perform(player_id, vicinity.id, :eat, index)
    View.render_eat(result, vicinity, player, ap, hp)

    case result do
      {:ok, _item, _effect, new_ap, new_hp} -> {new_ap, new_hp}
      {:error, :not_edible, _item_name} -> {ap, hp}
      {:error, :invalid_index} -> {ap, hp}
      {:error, _reason} -> {ap, hp}
    end
  end

  defp handle_inventory(player, player_id, vicinity) do
    items = Gateway.check_inventory(player_id)
    View.render_inventory(items, vicinity, player)
  end

  defp handle_scribble(player, player_id, vicinity, ap, hp, text) do
    result = Gateway.perform(player_id, vicinity.id, :scribble, text)
    View.render_scribble(result, vicinity, player, ap, hp)

    case result do
      {:ok, new_ap} -> new_ap
      {:error, _reason} -> ap
    end
  end

  def parse("look"), do: :look
  def parse("l"), do: :look
  def parse("search"), do: :search
  def parse("inventory"), do: :inventory
  def parse("i"), do: :inventory
  def parse("quit"), do: :quit
  def parse("q"), do: :quit

  def parse("drop " <> index_str) do
    case Integer.parse(index_str) do
      {n, ""} when n >= 1 -> {:drop, n - 1}
      _ -> :unknown
    end
  end

  def parse("eat " <> index_str) do
    case Integer.parse(index_str) do
      {n, ""} when n >= 1 -> {:eat, n - 1}
      _ -> :unknown
    end
  end

  def parse("scribble " <> text), do: {:scribble, text}

  def parse(input) do
    case Map.fetch(@directions, input) do
      {:ok, direction} -> {:move, direction}
      :error -> :unknown
    end
  end
end
