defmodule UndercityServer.Gateway do
  @moduledoc """
  Single entry point for all CLI interactions with the game server.

  - Routes `perform/4` calls to the appropriate `Actions.*` module
  - Delegates session, inventory, and inbox calls to `Session`, `Player`, and `Player.Inbox`
  - Enforces block-presence validation before dispatching most actions
  - To add a new action: implement it in an `Actions.*` module, then add a `perform` clause here
  """

  alias UndercityServer.Actions
  alias UndercityServer.Block
  alias UndercityServer.Player

  @doc """
  Connects to the server node and enters `player_name` into the world.

  - Returns `{:ok, {player_id, vicinity, constitution}}` on success.
  - Returns `{:error, :server_not_found}` if the server node cannot be reached after retries.
  - Returns `{:error, :server_down}` if the node is unreachable.
  - Returns `{:error, :invalid_name}` if the name contains disallowed characters.
  """
  defdelegate connect(player_name), to: UndercityServer.Session

  @doc """
  Enters `name` into the world directly, without attempting a node connection.

  - Returns `{player_id, vicinity, constitution}` for both new and returning players.
  - Returns `{:error, :invalid_name}` if the name contains disallowed characters.
  """
  defdelegate enter(name), to: UndercityServer.Session

  @doc """
  Returns the list of items currently in the player's inventory.
  """
  defdelegate check_inventory(player_id), to: Player

  @doc """
  Drops the item at `index` from the player's inventory, spending 1 AP.

  - Returns `{:ok, ap}` on success.
  - Returns `{:ok, ap}` unchanged if no item exists at that position (silent noop).
  - Returns `{:error, :exhausted}` or `{:error, :collapsed}` if the player cannot spend AP.
  """
  defdelegate drop_item(player_id, index), to: Player

  @doc """
  Returns and clears pending inbox messages for `player_id`.

  Reads the ETS-backed `Player.Inbox` directly — no GenServer hop required.
  Returns up to 50 messages in newest-first order. Returns `[]` if there
  are no messages.
  """
  @spec messages_for(String.t()) :: [{String.t()}]
  def messages_for(player_id) do
    Player.fetch_inbox(player_id)
  end

  @doc """
  Dispatches a player action to the appropriate `Actions.*` module.

  - The `:eat` action does not require block-presence validation and is dispatched directly.
    Returns `{:ok, ap, hp}` on success or silent noop (out of range, not edible).
    Returns `{:error, :exhausted}` or `{:error, :collapsed}` if AP cannot be spent.
  - All other actions require `player_id` to be present in `block_id`; returns `{:error, :not_in_block}` if not.
  - Supported actions: `:eat`, `:move`, `:search`, `:scribble`, `:attack`, `:heal`.
  """
  def perform(player_id, _block_id, :eat, index), do: Actions.Eat.eat(player_id, index)

  def perform(player_id, block_id, action, args) do
    if Block.has_person?(block_id, player_id) do
      dispatch(player_id, block_id, action, args)
    else
      {:error, :not_in_block}
    end
  end

  defp dispatch(player_id, block_id, :move, direction), do: Actions.Movement.move(player_id, block_id, direction)
  defp dispatch(player_id, block_id, :search, _args), do: Actions.Search.search(player_id, block_id)
  defp dispatch(player_id, block_id, :scribble, text), do: Actions.Scribble.scribble(player_id, block_id, text)

  defp dispatch(player_id, block_id, :attack, {target_id, weapon_index, attacker_name}),
    do: Actions.Attack.attack(player_id, attacker_name, block_id, target_id, weapon_index)

  defp dispatch(player_id, block_id, :heal, {target_id, item_idx, healer_name}),
    do: Actions.Heal.heal(player_id, healer_name, block_id, target_id, item_idx)
end
