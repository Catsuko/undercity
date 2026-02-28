defmodule UndercityCore.BlockType do
  @moduledoc """
  Canonical home for the `t()` typespec enumerating all valid block type atoms.

  Presentation concerns (descriptions, scribble surfaces, grammatical prefixes)
  belong in the CLI layer, not here.
  """

  @type t() :: :street | :square | :fountain | :graveyard | :space | :inn
end
