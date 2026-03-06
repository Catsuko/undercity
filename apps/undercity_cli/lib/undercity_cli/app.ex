defmodule UndercityCli.App do
  @moduledoc """
  Ratatouille TEA application for the Undercity CLI.

  Implements the Ratatouille.App behaviour: init/1, update/2, subscribe/1,
  and render/1. The state holds all display state and is updated either by
  subscription ticks (message polling) or keyboard events (input building and
  command dispatch).

  Context for init/1 is read from application env (`:undercity_cli, :context`)
  since Ratatouille's runtime only exposes terminal window info via its built-in
  context map.
  """

  @behaviour Ratatouille.App

  import Ratatouille.View

  alias Ratatouille.Runtime.Subscription
  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer
  alias UndercityCli.State
  alias UndercityCli.View.BlockDescription
  alias UndercityCli.View.Constitution
  alias UndercityCli.View.Status
  alias UndercityCli.View.Surroundings

  @panel_padding 1
  @max_log_size 35
  # Ratatouille 12-column grid: 10 (main) + 2 (message log)
  @main_col_size 10
  @log_col_size 2

  @impl true
  def init(context) do
    %{
      player: player,
      game_state: game_state,
      gateway: gateway
    } = Application.fetch_env!(:undercity_cli, :context)

    {:ok, _pid} = MessageBuffer.start_link()

    initial_messages = sync_messages(gateway, game_state.player_id)
    MessageBuffer.push(Constitution.status_messages(game_state.ap, game_state.hp))
    flushed = MessageBuffer.flush()

    %State{
      player_id: game_state.player_id,
      player_name: player,
      vicinity: game_state.vicinity,
      ap: game_state.ap,
      hp: game_state.hp,
      input: "",
      message_log: trim_log(initial_messages ++ flushed),
      gateway: gateway,
      window_width: context.window.width
    }
  end

  @impl true
  def update(state, msg) do
    case msg do
      {:sync_messages} ->
        new_msgs = sync_messages(state.gateway, state.player_id)
        flushed = MessageBuffer.flush()
        %{state | message_log: trim_log(state.message_log ++ new_msgs ++ flushed)}

      {:event, %{key: key}} when key == 13 ->
        # Enter key — dispatch the buffered input line
        dispatch_input(state)

      {:event, %{key: key}} when key == 127 or key == 8 ->
        # Backspace / ctrl-h
        new_input = String.slice(state.input, 0, max(0, String.length(state.input) - 1))
        %{state | input: new_input}

      {:event, %{key: key}} when key == 0x20 ->
        # Space (comes through as a key, not a character)
        %{state | input: state.input <> " "}

      {:event, %{ch: ch}} when ch > 0 ->
        # Printable character
        char = <<ch::utf8>>
        %{state | input: state.input <> char}

      _ ->
        state
    end
  end

  @impl true
  def subscribe(_state) do
    Subscription.interval(500, {:sync_messages})
  end

  @impl true
  def render(state) do
    left_col_width = div(state.window_width * @main_col_size, 12)

    view bottom_bar: bar(do: label(content: "> #{state.input}")) do
      panel title: "Undercity", height: :fill, padding: 0 do
        row do
          column size: @main_col_size do
            panel title: "Surroundings", padding: @panel_padding do
              Surroundings.render(state.vicinity, left_col_width)
            end

            panel title: "Location", padding: @panel_padding do
              BlockDescription.render(state.vicinity, state.player_name)
            end

            if state.pending do
              %{label: label, choices: choices} = state.pending
              n_choices = length(choices)

              panel title: label, padding: @panel_padding do
                choices
                |> Enum.with_index(1)
                |> Enum.map(fn {item, i} -> label(content: "#{i}. #{item.name}") end)
                |> Kernel.++([label(content: "#{n_choices + 1}. Cancel")])
              end
            end
          end

          column size: @log_col_size do
            panel title: "Log", height: :fill, padding: @panel_padding do
              Enum.map(state.message_log, fn {text, category} ->
                Status.format_message(text, category)
              end)
            end
          end
        end
      end
    end
  end

  # Fetches server inbox messages for player_id and returns them as
  # {text, :warning} tuples. Gateway returns {text} single-element tuples.
  defp sync_messages(gateway, player_id) do
    player_id
    |> gateway.messages_for()
    |> Enum.map(fn {text} -> {text, :warning} end)
  end

  defp dispatch_input(state) do
    old_ap = state.ap
    old_hp = state.hp

    new_state =
      case state.pending do
        nil ->
          raw = state.input |> String.trim() |> String.downcase()
          Commands.dispatch(raw, %{state | input: ""})

        pending ->
          handle_selection(state, pending)
      end

    threshold_msgs = Constitution.threshold_messages(old_ap, new_state.ap, old_hp, new_state.hp)
    MessageBuffer.push(threshold_msgs)
    flushed = MessageBuffer.flush()

    %{new_state | message_log: trim_log(new_state.message_log ++ flushed)}
  end

  defp handle_selection(state, pending) do
    n = length(pending.choices)

    case parse_selection(state.input, n) do
      {:ok, index} ->
        updated = state |> State.clear_pending() |> Map.put(:input, "")
        Commands.redispatch(pending.command, pending.args ++ [index], updated)

      :cancel ->
        state
        |> State.clear_pending()
        |> Map.put(:input, "")

      :invalid ->
        # Stay in pending mode, just clear input
        %{state | input: ""}
    end
  end

  defp parse_selection(input, n_choices) do
    case Integer.parse(String.trim(input)) do
      {i, ""} when i >= 1 and i <= n_choices -> {:ok, i - 1}
      {i, ""} when i == n_choices + 1 -> :cancel
      _ -> :invalid
    end
  end

  defp trim_log(log) do
    Enum.take(log, -@max_log_size)
  end
end
