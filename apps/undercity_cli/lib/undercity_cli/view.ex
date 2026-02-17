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
  alias UndercityCli.View.Status
  alias UndercityCli.View.Surroundings

  @inability_messages %{
    exhausted: {"You are too exhausted to act.", :warning},
    collapsed: {"Your body has given out.", :warning}
  }

  def render(vicinity, player) do
    IO.write([IO.ANSI.clear(), IO.ANSI.home()])
    Surroundings.render(vicinity)
    BlockDescription.render(vicinity, player)
  end

  defdelegate render_message(message), to: Status
  defdelegate render_constitution(ap, hp), to: Constitution, as: :render
  defdelegate render_constitution(ap, hp, old_ap), to: Constitution, as: :render
  defdelegate render_constitution(ap, hp, old_ap, old_hp), to: Constitution, as: :render

  defdelegate scribble_surface(vicinity), to: BlockDescription

  def render_move({:ok, {:ok, new_vicinity}, new_ap}, _vicinity, player, old_ap, hp) do
    render(new_vicinity, player)
    render_constitution(new_ap, hp, old_ap)
  end

  def render_move({:ok, {:error, :no_exit}, new_ap}, vicinity, player, ap, hp) do
    render(vicinity, player)
    render_message({"You can't go that way.", :warning})
    render_constitution(new_ap, hp, ap)
  end

  def render_move({:error, reason}, vicinity, player, _ap, _hp) do
    render(vicinity, player)
    render_message(inability_message(reason))
  end

  def render_search({:ok, {:found, item}, new_ap}, vicinity, player, ap, hp) do
    render(vicinity, player)
    render_message({"You found #{item.name}!", :success})
    render_constitution(new_ap, hp, ap)
  end

  def render_search({:ok, {:found_but_full, item}, new_ap}, vicinity, player, ap, hp) do
    render(vicinity, player)
    render_message({"You found #{item.name}, but your inventory is full.", :warning})
    render_constitution(new_ap, hp, ap)
  end

  def render_search({:ok, :nothing, new_ap}, vicinity, player, ap, hp) do
    render(vicinity, player)
    render_message({"You find nothing.", :warning})
    render_constitution(new_ap, hp, ap)
  end

  def render_search({:error, reason}, vicinity, player, _ap, _hp) do
    render(vicinity, player)
    render_message(inability_message(reason))
  end

  def render_inventory(items, vicinity, player) do
    render(vicinity, player)

    case items do
      [] -> render_message({"Your inventory is empty.", :info})
      items -> render_message({"Inventory: #{Enum.map_join(items, ", ", & &1.name)}", :info})
    end
  end

  def render_drop({:ok, item_name, new_ap}, vicinity, player, ap, hp) do
    render(vicinity, player)
    render_message({"You dropped #{item_name}.", :info})
    render_constitution(new_ap, hp, ap)
  end

  def render_drop({:error, :invalid_index}, vicinity, player, _ap, _hp) do
    render(vicinity, player)
    render_message({"Invalid item selection.", :warning})
  end

  def render_drop({:error, reason}, vicinity, player, _ap, _hp) do
    render(vicinity, player)
    render_message(inability_message(reason))
  end

  def render_eat({:ok, item, _effect, new_ap, new_hp}, vicinity, player, ap, hp) do
    render(vicinity, player)
    render_message({"Ate a #{item.name}.", :success})
    render_constitution(new_ap, new_hp, ap, hp)
  end

  def render_eat({:error, :not_edible, item_name}, vicinity, player, _ap, _hp) do
    render(vicinity, player)
    render_message({"You can't eat #{item_name}.", :warning})
  end

  def render_eat({:error, :invalid_index}, vicinity, player, _ap, _hp) do
    render(vicinity, player)
    render_message({"Invalid item selection.", :warning})
  end

  def render_eat({:error, reason}, vicinity, player, _ap, _hp) do
    render(vicinity, player)
    render_message(inability_message(reason))
  end

  def render_scribble({:ok, new_ap}, vicinity, player, old_ap, hp) do
    render(vicinity, player)
    render_message({"You scribble #{scribble_surface(vicinity)}.", :success})
    render_constitution(new_ap, hp, old_ap)
  end

  def render_scribble({:error, :empty_message}, vicinity, player, _ap, _hp) do
    render(vicinity, player)
    render_message({"You scribble #{scribble_surface(vicinity)}.", :success})
  end

  def render_scribble({:error, :item_missing}, vicinity, player, _ap, _hp) do
    render(vicinity, player)
    render_message({"You have no chalk.", :warning})
  end

  def render_scribble({:error, reason}, vicinity, player, _ap, _hp) do
    render(vicinity, player)
    render_message(inability_message(reason))
  end

  def render_unknown_command(vicinity, player) do
    render(vicinity, player)

    render_message(
      {"Unknown command. Try: look, search, inventory, drop <n>, eat <n>, scribble <text>, north/south/east/west (or n/s/e/w), enter, exit, quit",
       :warning}
    )
  end

  defp inability_message(reason), do: Map.fetch!(@inability_messages, reason)
end
