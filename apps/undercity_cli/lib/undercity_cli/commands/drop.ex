defmodule UndercityCli.Commands.Drop do
  @moduledoc "Handles drop commands (bare and indexed)."

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer
  alias UndercityCli.State

  def usage, do: "drop [n]"

  # Bare "drop" — fetch inventory and set up selection overlay
  def dispatch("drop", state) do
    case state.gateway.check_inventory(state.player_id) do
      [] ->
        MessageBuffer.warn("Your inventory is empty.")
        state

      items ->
        state
        |> State.pending("drop", [])
        |> State.select("Drop which item?", items)
    end
  end

  # Typed "drop 1" — parse index and execute
  def dispatch({"drop", index_str}, state) do
    case Integer.parse(index_str) do
      {n, ""} when n >= 1 ->
        do_drop(n - 1, state)

      _ ->
        MessageBuffer.warn("Invalid item selection.")
        state
    end
  end

  # Re-dispatch after overlay selection — index is 0-based
  def dispatch("drop", index, state) when is_integer(index) do
    do_drop(index, state)
  end

  defp do_drop(index, state) do
    state.player_id
    |> state.gateway.drop_item(index)
    |> Commands.handle_action(state, fn
      {:ok, item_name, new_ap}, state ->
        MessageBuffer.info("You dropped #{item_name}.")
        %{state | ap: new_ap}

      {:error, :invalid_index}, state ->
        MessageBuffer.warn("Invalid item selection.")
        state
    end)
  end
end
