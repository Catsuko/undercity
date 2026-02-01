# Undercity

A multiplayer persistent text game set in a dark medieval zombie apocalypse.

## Prerequisites

- Erlang/OTP 26+
- Elixir 1.19+

## Setup

```bash
mix deps.get
mix compile
```

## Running

Start the game server:

```bash
elixir --name undercity_server@127.0.0.1 -S mix undercity.server --name my_server
```

Join as a player (in a separate terminal):

```bash
elixir --name client@127.0.0.1 -S mix undercity.join --server my_server --player your_name
```

## Project Structure

This is an Elixir umbrella project with two apps:

- `undercity_core` - Game engine, logic, and OTP supervision
- `undercity_cli` - CLI client interface

## Tests

```bash
mix test
```
