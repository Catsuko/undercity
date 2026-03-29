# Docs Index

This is a comprehensive map of this project's documentation pages with their headings, designed for easy navigation by LLMs.

## Document Structure

This map uses a hierarchical structure:

* **##** marks documentation groups (e.g., 'Getting started')
* **###** marks individual documentation pages or sub directories
* **Nested bullets** show the heading structure and content within each page

## System

Architecture and runtime behaviour.

### [Architecture](architecture.md)

- Three Apps
  - `undercity_core` — pure domain logic
  - `undercity_server` — OTP processes, named node, DETS persistence
  - `undercity_cli` — distributed Erlang client, terminal UI
- Key Design Decisions
  - Distributed Erlang for client-server
  - CLI knows nothing about core
  - Pure core, stateful server
  - Lazy AP regeneration
  - Location tracked by blocks, not players
- Supervision Tree
- World Model
- Request Lifecycle
- Persistence

### [Persistence](persistence.md)

- Two Stores
  - Player store — single shared DETS table
  - Block store — one DETS file per world block
- Key Properties
  - Synchronous writes
  - On-restart recovery
  - Test isolation
- Resetting

### [Actions and Commands](actions.md)

- The Pipeline
- CLI Side
- Result Shapes
- Adding a New Action

## Testing

### [Testing](testing.md)

- Three Layers
  - `undercity_core` — pure unit tests
  - `undercity_server` — GenServer and integration tests
  - `undercity_cli` — command dispatch and view tests
- Test.Helpers (server tests)
  - Start supervised block and player processes with isolated DETS state
  - Automatic cleanup on exit
  - Unique test data generation (e.g. player IDs and names)
- CLI Mocking
- Common Patterns
  - Deterministic loot rolls
  - AP exhaustion
  - Collapsed player

## World

### [World Building Guide](world_building.md)

- Block ID Conventions
- Exterior and Interior Blocks
  - Exterior blocks
  - Interior blocks
  - Linking exterior to interior
  - Interior block names
  - Interior block neighbourhood
  - Inside detection
- Block Types
  - Types with interiors (15 types)
  - Types without interiors
- Naming Conventions
  - Buildings
  - Streets
  - Open spaces
- District Layout Rules
- Connections
  - Grid connections
  - Enter / exit connections
  - District-to-district connections
  - Connection counts
- The Ashwarden Quarter
  - Grid layout
  - Block type counts
- Add a New District

### [District Maps](districts)

This directory contains maps for specific districts:

- Description
- Block names by position

## Conventions

### [Writing Guide](writing.md)

- Structure
- Prose
- Lists and tables
- Code
- Length

### [Code Documentation Styleguide](code_docs.md)

- Principles
- `@moduledoc`
- `@doc`
- What not to document
