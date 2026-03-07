defmodule UndercityCli.Commands.Selection do
  @moduledoc """
  Shared helpers for commands that need a selector overlay before they can execute.

  Two entry points cover the common data sources:
  - `from_inventory/5` — fetches the player's inventory via gateway, then prompts selection
  - `from_people/5`   — reads people from the current vicinity, then prompts selection

  Both delegates to `from_list/6`, which handles the empty/nil guard and sets up
  the pending selection state.
  """

  alias UndercityCli.MessageBuffer
  alias UndercityCli.State

  @doc """
  Fetches the player's inventory and presents a selector overlay.
  Shows `empty_warning` and returns state unchanged if inventory is empty.
  """
  def from_inventory(state, command, empty_warning, prompt), do: from_inventory(state, command, [], empty_warning, prompt)

  def from_inventory(state, command, args, empty_warning, prompt) do
    items = state.gateway.check_inventory(state.player_id)
    from_list(state, items, command, args, empty_warning, prompt)
  end

  @doc """
  Reads people from the current vicinity and presents a selector overlay.
  Shows `empty_warning` and returns state unchanged if no people are present.
  """
  def from_people(state, command, empty_warning, prompt), do: from_people(state, command, [], empty_warning, prompt)

  def from_people(state, command, args, empty_warning, prompt) do
    from_list(state, state.vicinity.people, command, args, empty_warning, prompt)
  end

  @doc """
  Presents a selector overlay from a pre-fetched list.
  Shows `empty_warning` and returns state unchanged if the list is nil or empty.
  """
  def from_list(state, items, command, args, empty_warning, prompt) do
    case items do
      items when items in [nil, []] ->
        MessageBuffer.warn(empty_warning)
        state

      items ->
        state
        |> State.pending(command, args)
        |> State.select(prompt, items)
    end
  end
end
