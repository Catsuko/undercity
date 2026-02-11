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
elixir --name undercity_server@127.0.0.1 -S mix undercity.server
```

Join as a player (in a separate terminal):

```bash
elixir --name client@127.0.0.1 -S mix undercity.join --player your_name
```

## Project Structure

This is an Elixir umbrella project with three apps:

- `undercity_core` - Pure domain logic (structs and functions, no OTP)
- `undercity_server` - OTP server and supervision
- `undercity_cli` - CLI client interface

## Tests

```bash
mix test
```
