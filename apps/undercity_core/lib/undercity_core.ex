defmodule UndercityCore do
  @moduledoc """
  Pure domain logic for the Undercity — no OTP, no processes, no side effects.

  All runtime state lives in `UndercityServer`. This app defines the structs and
  functions that both the server and its tests build on.

  ## Domain

  - The world is made up of **blocks** — named locations connected by exits. Players
    move between them and spend action points (AP) to act.
  - Each player has an **AP pool** and a **health pool (HP)**. At 0 AP they are
    exhausted; at 0 HP they are collapsed and cannot act at all.
  - AP regenerates over time; HP does not regenerate on its own.
  - Players carry a bounded **inventory** of items found by searching blocks. Each
    block type has its own loot table.
  - Items can be **edible** (applying a random health effect on consumption) or
    **consumable tools** — e.g. Chalk is spent to write scribble messages on blocks.
  """
end
