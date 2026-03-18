# World Building Guide

The canonical reference for authors adding new districts and blocks to Undercity. Covers block IDs, the exterior/interior model, block types, naming conventions, district layout rules, and the connection model.

The Ashwarden Quarter is referenced throughout as a concrete example. Treat it as illustration, not template — new districts should have their own character in layout, density, and block mix. Repeating Ashwarden's structure produces a world that feels like one district copy-pasted.

## Block ID Conventions

Block IDs are lowercase `snake_case` strings derived from the display name:

- Spaces become underscores: `Hollow House` → `hollow_house`
- Apostrophes are dropped: `Warden's Archive` → `wardens_archive`
- Leading "The" is dropped: `The Cobweb Inn` → `cobweb_inn`
- Interior blocks take a `_interior` suffix: `wardens_archive_interior`
- Street cells each get a unique name — no shared route IDs, no positional suffixes like `_r0` or `_c0`

| Display Name               | Block ID                       | Notes                  |
|----------------------------|--------------------------------|------------------------|
| Warden's Archive           | `wardens_archive`              | Apostrophe dropped     |
| Warden's Archive (interior)| `wardens_archive_interior`     | `_interior` suffix     |
| The Cobweb Inn             | `cobweb_inn`                   | Leading "The" dropped  |
| Church of the Hollow Saint | `church_of_the_hollow_saint`   | Full name retained     |
| Cooper's Lane              | `coopers_lane`                 | Apostrophe dropped     |

## Exterior and Interior Blocks

Every enterable building occupies two blocks: an exterior block on the grid and an interior block reachable via `enter`.

### Exterior blocks

Exterior blocks have `"type": "space"` in `world.json`. The CLI renders them as *"You are outside [name]"*. They sit on the 10×10 grid and expose N/E/S/W movement plus an `enter` command.

### Interior blocks

Interior blocks have the actual semantic type (`inn`, `tavern`, `guild`, etc.). The CLI renders them as *"You are inside [name]"*. They have no grid position and no N/E/S/W connections — only `exit`.

### Linking exterior to interior

Declare the connection once as an `enter` direction from the exterior block:

```json
["wardens_archive", "enter", "wardens_archive_interior"]
```

`WorldMap` derives `exit` automatically. Never declare `exit` connections manually.

### Interior block names

Both the exterior and interior block use the same `name` value:

```json
{"id": "wardens_archive",          "name": "Warden's Archive", "type": "space"},
{"id": "wardens_archive_interior", "name": "Warden's Archive", "type": "archive"}
```

Do not add `(Interior)` or any suffix to the interior block's `name` — it appears verbatim in CLI output.

### Interior block neighbourhood

`WorldMap.surrounding/1` checks whether a block ID is on the grid. If not, it follows `:exit` to the parent block and returns that neighbourhood. Interior blocks share their building's surrounding context.

### Inside detection

- `WorldMap.building_type/1` — looks up the `:enter` exit for a given exterior block and returns the interior block's type.
- `Vicinity.inside?/1` — returns `true` when the neighbourhood centre has a `building_type` and the vicinity's own `building_type` is `nil` (the player is inside a building, not standing outside it).

## Block Types

Blocks fall into two categories: types with interiors (enterable buildings) and types without interiors (open spaces).

### Types with interiors

These 15 types always appear as a `space` exterior paired with a typed interior:

| Type         | Description                             |
|--------------|-----------------------------------------|
| `apothecary` | Medicine, remedies, and potions         |
| `archive`    | Records, documents, accumulated knowledge |
| `bazaar`     | Open market stall or trading floor      |
| `bell_tower` | Landmark tower; one per district at most |
| `blacksmith` | Metalwork, weapons, and tools           |
| `church`     | Place of worship                        |
| `dungeon`    | Underground cells or holding area       |
| `garrison`   | Guard post or military barracks         |
| `guild`      | Trade or professional guild hall        |
| `inn`        | Lodging and rest                        |
| `manor`      | Upper-class residence                   |
| `storehouse` | Goods storage and warehousing           |
| `tavern`     | Drinking and gathering                  |
| `townhouse`  | Ordinary residential dwelling           |
| `workshop`   | Crafting and manufacturing              |

### Types without interiors

These types exist only as grid blocks with no `enter` connection:

| Type        | Description                             |
|-------------|-----------------------------------------|
| `street`    | Walkable route connecting buildings     |
| `square`    | Open public space, often a social anchor |
| `fountain`  | Water feature; decorative or functional |
| `graveyard` | Burial ground                           |

`space` is an implementation detail for exterior blocks — never assign it directly.

## Naming Conventions

### Buildings

Use names that feel lived-in: reference owners, local history, or physical character.

- **Owner names**: Maren's Apothecary, Hobb's Remedies, Kazan's Stall
- **Local references**: Lethemoor Hall, Suthen Estate, Raven Manor
- **Physical character**: The Cobweb Inn, The Tallow Candle, The Buckled Boot, Deep Hold

Avoid generic names like "The Apothecary" or "The Guild Hall" — every building needs a proper name.

### Streets

Give each street cell its own unique name. Mix across three categories:

- **Trade / occupation**: Cooper's Lane, Tanner's Row, Vestry Lane, Cordwainer's Row
- **Geographic / directional**: Low Lane, East Street, Bell Crossing, Long Row
- **Local character**: Forge Cut, Malt Cut, Broad Alley, Cloister Alley

Mix these name types across a district: `lane`, `alley`, `street`, `row`, `court`, `way`, `walk`, `cut`, `passage`, `crescent`, `close`, `avenue`.

Keep street names mundane and grounded. Avoid thematic or ominous names.

### Open spaces

Give fountains, squares, and graveyards proper names that fit the neighbourhood: Suthen Well, Alderman's Well, Ashwarden Square, Wormgarden, Ashwarden Grove.

## District Layout Rules

Each district is a 10×10 grid (100 blocks). These are guidelines, not hard constraints. Violations are fine if deliberate.

| Block Type    | Placement Rules |
|---------------|-----------------|
| `apothecary`  | 1–4 per district; at least 3 blocks apart from each other |
| `archive`     | 0–1 per district; typically adjacent to a `church` or `guild` |
| `bazaar`      | 0–2 per district; loosely near `square` if one exists (within 2 blocks), but may appear alone |
| `bell_tower`  | 0–1 per district; landmark position, not adjacent to other tall structures |
| `blacksmith`  | 2–4 per district; away from `church` and `manor`, not in residential centre |
| `church`      | 0–3 per district; not adjacent to `dungeon` or `tavern` |
| `dungeon`     | 0–1 per district; within 2 blocks of a `garrison` or `guild` |
| `fountain`    | 0–2 per district; loosely near `square` or `manor` if present |
| `garrison`    | 1–2 per district; spaced well apart if more than one |
| `graveyard`   | 1–2 per district; district edge preferred; at least 4 blocks apart; avoid adjacency to `square`, shops, or busy blocks |
| `guild`       | 1–4 per district; no strict placement requirements |
| `inn`         | 1–6 per district; at least 3 blocks from other `inn` blocks |
| `manor`       | 0–2 per district; away from `blacksmith` and `workshop`; clusters with `townhouse`; upmarket districts may have more manors and fewer `tavern`/`townhouse` |
| `square`      | 0–2 per district; anchor point for surrounding blocks, no strict position requirement |
| `storehouse`  | 2–4 per district; loosely near `blacksmith` or `workshop`, varied enough to avoid a noticeable pattern |
| `street`      | Creates simple routes between blocks; avoid over-use — prefer large contiguous building clusters over street-heavy layouts |
| `tavern`      | 2–4 per district; at least 2 blocks from other `tavern` blocks |
| `townhouse`   | Many; fills residential zones, may be adjacent to each other |
| `workshop`    | 1–4 per district; loosely near `blacksmith` or `storehouse`, varied enough to avoid a noticeable pattern |

## Connections

### Grid connections

Grid adjacency does **not** create connections automatically — every walkable pair must be declared explicitly in the `connections` array.

Declare connections once as directed edges; `WorldMap` derives the reverse automatically:

```json
["a", "east", "b"]
```

This also adds `["b", "west", "a"]` at compile time.

Valid direction strings: `"north"`, `"south"`, `"east"`, `"west"`, `"enter"`, `"exit"`. Any other string causes a compile-time `FunctionClauseError` in `WorldMap`.

There is no gating by block type — players can walk between any two adjacent exterior blocks regardless of type.

For a full 10×10 district:

- East connections: 10 rows × 9 pairs = 90
- South connections: 9 pairs × 10 columns = 90
- Total grid connections: 180

### Enter / exit connections

Reach interior blocks via `enter` connections:

```json
["building_exterior", "enter", "building_interior"]
```

`exit` is auto-derived. Interior blocks have no N/E/S/W connections.

### District-to-district connections

Connect districts at their edges by linking edge blocks in each district:

```json
["edge_block_a", "north", "edge_block_b"]
```

Each new district declares these connections explicitly.

### Connection counts (Ashwarden Quarter)

| Connection type   | Count   |
|-------------------|---------|
| East (grid)       | 90      |
| South (grid)      | 90      |
| Enter (interiors) | 55      |
| **Total**         | **235** |

## The Ashwarden Quarter

The first district: a 10×10 grid of 100 blocks with 55 enterable buildings, 155 blocks total. See [docs/districts/ashwarden_quarter.md](districts/ashwarden_quarter.md) for the full block listing.

### Grid layout

Row 0 is north; row 9 is south. Column 0 is west; column 9 is east.

```
     0  1  2  3  4  5  6  7  8  9
 0 [ %  #  .  +  a  .  g  ~  m  r ]
 1 [ #  #  .  ~  @  .  b  #  i  m ]
 2 [ .  .  .  .  .  .  .  .  .  . ]
 3 [ i  #  .  #  #  p  #  .  #  # ]
 4 [ s  s  .  #  g  t  #  .  #  # ]
 5 [ k  w  .  #  #  .  #  .  #  # ]
 6 [ .  .  .  .  .  .  .  .  .  . ]
 7 [ k  w  #  p  #  t  i  .  t  # ]
 8 [ #  #  #  s  .  #  g  .  d  r ]
 9 [ #  #  ^  .  .  .  .  .  .  % ]
```

Symbol legend:

| Symbol | Type         | Symbol | Type       |
|--------|--------------|--------|------------|
| `#`    | townhouse    | `@`    | square     |
| `.`    | street       | `~`    | fountain   |
| `%`    | graveyard    | `+`    | church     |
| `a`    | archive      | `g`    | guild      |
| `i`    | inn          | `m`    | manor      |
| `b`    | bazaar       | `p`    | apothecary |
| `k`    | blacksmith   | `w`    | workshop   |
| `s`    | storehouse   | `t`    | tavern     |
| `r`    | garrison     | `d`    | dungeon    |
| `^`    | bell_tower   |        |            |

### Block type counts

| Type        | Count |
|-------------|-------|
| street      | 40    |
| townhouse   | 28    |
| guild       | 3     |
| inn         | 3     |
| storehouse  | 3     |
| tavern      | 3     |
| apothecary  | 2     |
| blacksmith  | 2     |
| fountain    | 2     |
| garrison    | 2     |
| graveyard   | 2     |
| manor       | 2     |
| workshop    | 2     |
| archive     | 1     |
| bazaar      | 1     |
| bell_tower  | 1     |
| church      | 1     |
| dungeon     | 1     |
| square      | 1     |
| **Total**   | **100** |

## Add a New District

1. **Design the grid** — sketch a 10×10 layout following the placement rules above.
2. **Name every block** — apply the naming conventions; every block needs a unique name and ID.
3. **Identify enterable buildings** — any block that needs an interior gets a `space` exterior plus a typed interior; the `name` field must match exactly on both.
4. **Write `world.json` entries** — add all blocks to `blocks`; add the district rows to `grid`.
5. **Declare grid connections** — 90 east + 90 south for a standalone district; adjacency in `grid` does not create connections automatically.
6. **Declare enter connections** — one `["exterior_id", "enter", "interior_id"]` per enterable building; use only the six valid direction strings.
7. **Connect to the existing map** — declare connections from this district's edge blocks to the adjacent district's edge blocks.
8. **Add a district doc** — create `docs/districts/<district_name>.md` with a one-line description and the block layout. See `docs/districts/ashwarden_quarter.md` as a reference.
9. **Run `mix test`** — direction typos cause compile-time errors; block type typos (`"tavrn"`) compile silently but crash the CLI at runtime.

### Spawn block

`WorldMap.spawn_block/0` is hardcoded to `"ashwarden_square"` in `world_map.ex`. New players always start there. If a new district is intended as the starting area, update `world_map.ex` as well.
