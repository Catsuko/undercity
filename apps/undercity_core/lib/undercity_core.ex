defmodule UndercityCore do
  @moduledoc """
  Domain logic for the undercity.

  The undercity is a persistent world that players inhabit. Players exist in the
  world even when they are not connected — there is no logout or disconnect concept.
  Connecting simply means waking up where you already are.

  This module contains pure domain structs and functions with no OTP dependencies.

  ## Models

  ### Block

  A block is a location in the undercity where people can gather. Each block has an id,
  a name, a type, and a set of player IDs currently present.

  See `UndercityCore.Block`.

  ### Inventory

  A bounded collection of items a player can carry.

  See `UndercityCore.Inventory`.

  ### Item

  An item that can be found and carried.

  See `UndercityCore.Item`.
  """
end
