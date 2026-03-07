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

  # Typed "drop 1" — parse index and delegate to canonical form
  def dispatch({"drop", index_str}, state) when is_binary(index_str) do
    case Integer.parse(index_str) do
      {n, ""} when n >= 1 -> dispatch({"drop", n - 1}, state)
      _ -> handle_outcome({:error, :invalid_index}, state)
    end
  end

  # Canonical form — execute
  def dispatch({"drop", index}, state) when is_integer(index) do
    state.player_id
    |> state.gateway.drop_item(index)
    |> Commands.handle_action(state, &handle_outcome/2)
  end

  defp handle_outcome({:ok, item_name, new_ap}, state) do
    MessageBuffer.info("You dropped #{item_name}.")
    %{state | ap: new_ap}
  end

  defp handle_outcome({:error, :invalid_index}, state) do
    MessageBuffer.warn("Invalid item selection.")
    state
  end
end
