defmodule UndercityCli.App do
  @moduledoc """
  Ratatouille TEA application for the Undercity CLI.

  Implements the Ratatouille.App behaviour: init/1, update/2, subscribe/1,
  and render/1. The model holds all display state and is updated either by
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
  alias UndercityCli.View.BlockDescription
  alias UndercityCli.View.Constitution
  alias UndercityCli.View.Status
  alias UndercityCli.View.Surroundings

  @panel_padding 1

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

    %{
      player_id: game_state.player_id,
      player_name: player,
      vicinity: game_state.vicinity,
      ap: game_state.ap,
      hp: game_state.hp,
      input: "",
      messages: initial_messages ++ flushed,
      gateway: gateway,
      pending: nil,
      window_width: context.window.width
    }
  end

  @impl true
  def update(model, msg) do
    case msg do
      {:sync_messages} ->
        new_msgs = sync_messages(model.gateway, model.player_id)
        flushed = MessageBuffer.flush()
        %{model | messages: model.messages ++ new_msgs ++ flushed}

      {:event, %{key: key}} when key == 13 ->
        # Enter key — dispatch the buffered input line
        dispatch_input(model)

      {:event, %{key: key}} when key == 127 or key == 8 ->
        # Backspace / ctrl-h
        new_input = String.slice(model.input, 0, max(0, String.length(model.input) - 1))
        %{model | input: new_input}

      {:event, %{ch: ch}} when ch > 0 ->
        # Printable character
        char = <<ch::utf8>>
        %{model | input: model.input <> char}

      _ ->
        model
    end
  end

  @impl true
  def subscribe(_model) do
    Subscription.interval(500, {:sync_messages})
  end

  @impl true
  def render(model) do
    view bottom_bar: bar(do: label(content: "> #{model.input}")) do
      panel title: "Undercity", height: :fill, padding: @panel_padding do
        panel title: "Surroundings", padding: @panel_padding do
          Surroundings.render(model.vicinity, model.window_width)
        end

        panel title: "Location", padding: @panel_padding do
          BlockDescription.render(model.vicinity, model.player_name)
        end

        panel title: "Messages", padding: @panel_padding do
          Enum.map(model.messages, fn {text, category} ->
            Status.format_message(text, category)
          end)
        end
      end
    end
  end

  # Syncs server inbox messages for player_id into MessageBuffer and returns
  # the list of {text, category} tuples that were pushed.
  defp sync_messages(gateway, player_id) do
    messages = gateway.messages_for(player_id)
    Enum.each(messages, fn {text, _cat} -> MessageBuffer.warn(text) end)
    messages
  end

  defp dispatch_input(model) do
    raw = model.input |> String.trim() |> String.downcase()
    game_state = to_game_state(model)

    case Commands.dispatch(raw, game_state, model.gateway, MessageBuffer) do
      {:moved, new_state} ->
        threshold_msgs =
          Constitution.threshold_messages(model.ap, new_state.ap, model.hp, new_state.hp)

        MessageBuffer.push(threshold_msgs)
        flushed = MessageBuffer.flush()

        model
        |> apply_state(new_state)
        |> Map.update!(:messages, &(&1 ++ flushed))
        |> Map.put(:input, "")

      {:continue, new_state} ->
        threshold_msgs =
          Constitution.threshold_messages(model.ap, new_state.ap, model.hp, new_state.hp)

        MessageBuffer.push(threshold_msgs)
        flushed = MessageBuffer.flush()

        model
        |> apply_state(new_state)
        |> Map.update!(:messages, &(&1 ++ flushed))
        |> Map.put(:input, "")
    end
  end

  defp to_game_state(model) do
    %UndercityCli.GameState{
      player_id: model.player_id,
      player_name: model.player_name,
      vicinity: model.vicinity,
      ap: model.ap,
      hp: model.hp
    }
  end

  defp apply_state(model, new_state) do
    %{
      model
      | vicinity: new_state.vicinity,
        ap: new_state.ap,
        hp: new_state.hp
    }
  end
end
