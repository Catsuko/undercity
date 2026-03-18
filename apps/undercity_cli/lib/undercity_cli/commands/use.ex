defmodule UndercityCli.Commands.Use do
  @moduledoc """
  Handles the use command.

  Supports a full selection pipeline:
  - `use` → item overlay → target overlay → execute
  - `use <n>` → skips item overlay, opens target overlay
  - `use <n> <target>` → execute directly (n is the 1-based item index)

  Selection confirm stages (routed via Commands.dispatch/3):
  - `{"use", item_idx}` when integer → resolve item, show target overlay
  - `{"use", item_idx, target_idx}` when integer+integer → execute (selector path)
  - `{"use", item_idx, target_name}` when integer+binary → execute (typed path)
  """

  alias UndercityCli.Commands
  alias UndercityCli.Commands.Selection
  alias UndercityCli.MessageBuffer

  def usage, do: "use [n] [target]"

  # Bare "use" — set up inventory selection
  def dispatch(verb, state) when is_binary(verb) do
    Selection.from_inventory(state, verb, "Your inventory is empty.", "Use which item?")
  end

  # Typed "use 1" or "use 1 Zara" — parse and re-dispatch
  def dispatch({verb, rest}, state) when is_binary(rest) do
    case String.split(rest, " ", parts: 2) do
      [n_str] ->
        case Integer.parse(n_str) do
          {n, ""} when n >= 1 -> dispatch({verb, n - 1}, state)
          _ -> invalid_item(state)
        end

      [n_str, target_name] ->
        case Integer.parse(n_str) do
          {n, ""} when n >= 1 -> dispatch({verb, n - 1, target_name}, state)
          _ -> invalid_item(state)
        end
    end
  end

  # After InventorySelector confirm OR "use <n>" — resolve item, show target selector
  def dispatch({verb, item_idx}, state) when is_integer(item_idx) do
    items = state.gateway.check_inventory(state.player_id)

    case Enum.at(items, item_idx) do
      nil ->
        invalid_item(state)

      _item ->
        Selection.from_people(state, verb, [item_idx], "There is no one else here.", "Use on who?")
    end
  end

  # Selector path: item_idx from pending args, target_idx from TargetSelector confirm
  def dispatch({_verb, item_idx, target_idx}, state) when is_integer(item_idx) and is_integer(target_idx) do
    target = Enum.at(state.vicinity.people, target_idx)
    execute(item_idx, target.id, target.name, state)
  end

  # Typed path: item_idx and target_name from input parsing
  def dispatch({_verb, item_idx, target_name}, state) when is_integer(item_idx) and is_binary(target_name) do
    items = state.gateway.check_inventory(state.player_id)

    case Enum.at(items, item_idx) do
      nil ->
        invalid_item(state)

      _item ->
        case find_person(state.vicinity.people, target_name) do
          {:ok, person} -> execute(item_idx, person.id, person.name, state)
          {:error, :invalid_target} -> not_here(target_name, state)
        end
    end
  end

  defp execute(item_idx, target_id, target_name, state) do
    is_self = target_id == state.player_id
    result = state.gateway.perform(state.player_id, state.vicinity.id, :heal, {target_id, item_idx, state.player_name})
    Commands.handle_action(result, state, &handle_outcome(&1, &2, target_name, is_self))
  end

  defp handle_outcome({:ok, {:healed, _target_id, new_ap, healed}}, state, _target_name, true) do
    MessageBuffer.success("You healed yourself for #{healed}.")
    %{state | ap: new_ap, hp: state.hp + healed}
  end

  defp handle_outcome({:ok, {:healed, _target_id, new_ap, healed}}, state, target_name, false) do
    MessageBuffer.success("You healed #{target_name} for #{healed}.")
    %{state | ap: new_ap}
  end

  defp handle_outcome({:error, :item_missing}, state, _target_name, _is_self) do
    MessageBuffer.warn("You don't have that anymore.")
    state
  end

  defp handle_outcome({:error, :not_a_remedy}, state, _target_name, _is_self) do
    MessageBuffer.warn("You can't use that.")
    state
  end

  defp handle_outcome({:error, :invalid_target}, state, target_name, _is_self) do
    not_here(target_name, state)
  end

  defp invalid_item(state) do
    MessageBuffer.warn("Invalid item selection.")
    state
  end

  defp not_here(name, state) do
    MessageBuffer.warn("#{name} can't be healed.")
    state
  end

  defp find_person(people, name) do
    case Enum.find(people || [], fn p -> p.name == name end) do
      nil -> {:error, :invalid_target}
      person -> {:ok, person}
    end
  end
end
