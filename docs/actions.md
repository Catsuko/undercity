# Actions and Commands

## The Pipeline

Player actions flow through a consistent pipeline:

```
CLI input → Commands.dispatch → Gateway.perform → Actions module → Player.perform → Block GenServer
```

**`Gateway`** is the single public API boundary between CLI and server. It routes `perform(player_id, block_id, action, args)` calls to the appropriate `Actions.*` module.

**`Actions.*` modules** (`actions/` directory in `undercity_server`) each implement a single action. They coordinate between the `Player` and `Block` GenServers.

**`Player.perform/3`** is the AP-gating helper used by most actions. It checks the player isn't collapsed, applies lazy AP regen, spends the AP cost, then runs the action function. Returns `{:ok, result, remaining_ap}`, `{:error, :exhausted}`, or `{:error, :collapsed}`. Some actions (drop, eat) handle AP inline inside the Player GenServer instead.

## CLI Side

**`Commands`** routes raw input strings to command modules via a compile-time verb→module map. Each command module implements `dispatch/4` (or `/5` for commands with an interactive selector), taking parsed input, `GameState`, a gateway module, and a message buffer module.

Commands return `{:continue, new_state}` or `{:moved, new_state}` via `GameState` helpers. The game loop only re-renders the surroundings view on `:moved`.

**`Commands.handle_action/4`** normalises `:exhausted` and `:collapsed` errors in one place — all commands pipe their gateway result through it, so the callback only receives non-error results.

## Result Shapes

| Action     | Success return                                                      |
|------------|---------------------------------------------------------------------|
| move       | `{:ok, {:ok, vicinity} \| {:error, :no_exit}, ap}`                |
| search     | `{:ok, {:found, item} \| {:found_but_full, item} \| :nothing, ap}` |
| scribble   | `{:ok, ap}`                                                         |
| eat        | `{:ok, item, effect, ap, hp}`                                       |
| drop       | `{:ok, item_name, ap}`                                              |

## Adding a New Action

1. Create an `Actions.MyAction` module in `undercity_server` with a single public function.
2. Add a `Player` GenServer callback if new player state needs to be read or mutated.
3. Add a `perform` clause to `Gateway` routing to the new action.
4. Create a `Commands.MyCommand` module in `undercity_cli` implementing `dispatch/4`.
5. Register the verb in `@command_routes` in `Commands`.
