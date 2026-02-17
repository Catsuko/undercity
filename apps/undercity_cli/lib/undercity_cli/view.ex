defmodule UndercityCli.View do
  @moduledoc """
  Formats server data for CLI display.

  Delegates to submodules:
  - `View.Surroundings` — neighbourhood grid
  - `View.BlockDescription` — block text, scribbles, people
  - `View.Constitution` — AP/HP tier status
  - `View.Status` — generic message formatting
  """

  alias UndercityCli.View.BlockDescription
  alias UndercityCli.View.Constitution
  alias UndercityCli.View.Screen

  @inability_messages %{
    exhausted: {"You are too exhausted to act.", :warning},
    collapsed: {"Your body has given out.", :warning}
  }

  defdelegate init(), to: Screen
  defdelegate read_input(), to: Screen
  defdelegate teardown(), to: Screen

  defdelegate scribble_surface(vicinity), to: BlockDescription

  def render(vicinity, player, messages \\ []) do
    Screen.update(vicinity, player, messages)
  end

  def render_move({:ok, {:ok, new_vicinity}, new_ap}, _vicinity, player, old_ap, hp) do
    render(new_vicinity, player, Constitution.threshold_messages(old_ap, new_ap, hp, hp))
  end

  def render_move({:ok, {:error, :no_exit}, new_ap}, vicinity, player, ap, hp) do
    messages = [{"You can't go that way.", :warning} | Constitution.threshold_messages(ap, new_ap, hp, hp)]
    render(vicinity, player, messages)
  end

  def render_move({:error, reason}, vicinity, player, _ap, _hp) do
    render(vicinity, player, [inability_message(reason)])
  end

  def render_search({:ok, {:found, item}, new_ap}, vicinity, player, ap, hp) do
    messages = [{"You found #{item.name}!", :success} | Constitution.threshold_messages(ap, new_ap, hp, hp)]
    render(vicinity, player, messages)
  end

  def render_search({:ok, {:found_but_full, item}, new_ap}, vicinity, player, ap, hp) do
    messages = [
      {"You found #{item.name}, but your inventory is full.", :warning}
      | Constitution.threshold_messages(ap, new_ap, hp, hp)
    ]

    render(vicinity, player, messages)
  end

  def render_search({:ok, :nothing, new_ap}, vicinity, player, ap, hp) do
    messages = [{"You find nothing.", :warning} | Constitution.threshold_messages(ap, new_ap, hp, hp)]
    render(vicinity, player, messages)
  end

  def render_search({:error, reason}, vicinity, player, _ap, _hp) do
    render(vicinity, player, [inability_message(reason)])
  end

  def render_inventory(items, vicinity, player) do
    message =
      case items do
        [] -> {"Your inventory is empty.", :info}
        items -> {"Inventory: #{Enum.map_join(items, ", ", & &1.name)}", :info}
      end

    render(vicinity, player, [message])
  end

  def render_drop({:ok, item_name, new_ap}, vicinity, player, ap, hp) do
    messages = [{"You dropped #{item_name}.", :info} | Constitution.threshold_messages(ap, new_ap, hp, hp)]
    render(vicinity, player, messages)
  end

  def render_drop({:error, :invalid_index}, vicinity, player, _ap, _hp) do
    render(vicinity, player, [{"Invalid item selection.", :warning}])
  end

  def render_drop({:error, reason}, vicinity, player, _ap, _hp) do
    render(vicinity, player, [inability_message(reason)])
  end

  def render_eat({:ok, item, _effect, new_ap, new_hp}, vicinity, player, ap, hp) do
    messages = [{"Ate a #{item.name}.", :success} | Constitution.threshold_messages(ap, new_ap, hp, new_hp)]
    render(vicinity, player, messages)
  end

  def render_eat({:error, :not_edible, item_name}, vicinity, player, _ap, _hp) do
    render(vicinity, player, [{"You can't eat #{item_name}.", :warning}])
  end

  def render_eat({:error, :invalid_index}, vicinity, player, _ap, _hp) do
    render(vicinity, player, [{"Invalid item selection.", :warning}])
  end

  def render_eat({:error, reason}, vicinity, player, _ap, _hp) do
    render(vicinity, player, [inability_message(reason)])
  end

  def render_scribble({:ok, new_ap}, vicinity, player, old_ap, hp) do
    messages = [
      {"You scribble #{scribble_surface(vicinity)}.", :success}
      | Constitution.threshold_messages(old_ap, new_ap, hp, hp)
    ]

    render(vicinity, player, messages)
  end

  def render_scribble({:error, :empty_message}, vicinity, player, _ap, _hp) do
    render(vicinity, player, [{"You scribble #{scribble_surface(vicinity)}.", :success}])
  end

  def render_scribble({:error, :item_missing}, vicinity, player, _ap, _hp) do
    render(vicinity, player, [{"You have no chalk.", :warning}])
  end

  def render_scribble({:error, reason}, vicinity, player, _ap, _hp) do
    render(vicinity, player, [inability_message(reason)])
  end

  def render_unknown_command(vicinity, player) do
    render(vicinity, player, [
      {"Unknown command. Try: look, search, inventory, drop <n>, eat <n>, scribble <text>, north/south/east/west (or n/s/e/w), enter, exit, quit",
       :warning}
    ])
  end

  defp inability_message(reason), do: Map.fetch!(@inability_messages, reason)
end
