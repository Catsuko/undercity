defmodule UndercityCore do
  @moduledoc """
  Domain logic for the undercity.

  The undercity is a persistent world that players inhabit. Players exist in the
  world even when they are not connected — there is no logout or disconnect concept.
  Connecting simply means waking up where you already are.

  This module contains pure domain structs and functions with no OTP dependencies.

  ## Models

  ### Person

  A person is an inhabitant of the undercity. Each person has a unique id and a name.
  Names are used to identify returning players when they reconnect.

  See `UndercityCore.Person`.

  ### Block

  A block is a location in the undercity where people can gather. Each block has an id,
  a name, a description, and a set of people currently present.

  See `UndercityCore.Block`.
  """
end
