defmodule UndercityCli.Spinner do
  @moduledoc """
  An animated spinner for CLI feedback during connection.

  Uses braille dot patterns with color cycling for a smooth, modern feel.
  """

  use GenServer

  @frames ~w(+ × + ×)
  @frame_rate 240
  @message_cycle_ms 4000

  # Muted colors using 256-color palette (greys with subtle tints)
  @colors [103, 109, 110, 116, 110, 109]

  # True color (24-bit) gradient for smooth text pulsing
  # Medium grey (180,180,180) → subtle cyan tint (160,195,205) → back to grey
  @text_pulse_base {180, 180, 180}
  @text_pulse_peak {160, 195, 205}
  @text_pulse_steps 30

  # Generate smooth gradient at compile time
  @text_pulse_colors (
                       half =
                         for i <- 0..(@text_pulse_steps - 1) do
                           t = i / (@text_pulse_steps - 1)
                           {br, bg, bb} = @text_pulse_base
                           {pr, pg, pb} = @text_pulse_peak

                           {
                             round(br + (pr - br) * t),
                             round(bg + (pg - bg) * t),
                             round(bb + (pb - bb) * t)
                           }
                         end

                       half ++ Enum.reverse(half)
                     )

  @messages [
    "Wading through the murk",
    "Listening for signs of life",
    "Feeling along cold stone walls",
    "Heaving the iron door",
    "Prying open the rusted gate",
    "Clawing through the rubble",
    "Lowering into the dark",
    "Kicking through the barricade",
    "Counting footsteps in the dark",
    "Drawing wards in the dirt",
    "Lighting torches in the gloom",
    "Praying to forgotten saints",
    "Scavenging for supplies",
    "Polishing old chainmail",
    "Checking the cracks in the wall",
    "Sharpening the blade",
    "Binding the wound tight",
    "Tracing sigils on the stone",
    "Whispering the old words"
  ]

  # Client API

  @doc """
  Starts the spinner with the given options.

  ## Options
    * `:message` - Initial message to display (default: first from rotation)
  """
  def start(opts \\ []) do
    GenServer.start(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Updates the spinner message.
  """
  def update(message) do
    GenServer.cast(__MODULE__, {:update, message})
  end

  @doc """
  Stops the spinner with a success message.
  """
  def success(message) do
    GenServer.call(__MODULE__, {:stop, :success, message})
  end

  @doc """
  Stops the spinner with a failure message.
  """
  def failure(message) do
    GenServer.call(__MODULE__, {:stop, :failure, message})
  end

  @doc """
  Stops the spinner without a final message.
  """
  def stop do
    GenServer.call(__MODULE__, :stop)
  catch
    :exit, _ -> :ok
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    state = %{
      frame_index: 0,
      color_index: 0,
      text_pulse_index: 0,
      message_index: :rand.uniform(length(@messages)) - 1,
      message: opts[:message]
    }

    schedule_frame()
    schedule_message_cycle()
    render(state)

    {:ok, state}
  end

  @impl true
  def handle_cast({:update, message}, state) do
    {:noreply, %{state | message: message}}
  end

  @impl true
  def handle_call({:stop, status, message}, _from, state) do
    clear_line()
    render_final(status, message)
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    clear_line()
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_info(:tick, state) do
    new_state = advance_frame(state)
    render(new_state)
    schedule_frame()
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:cycle_message, state) do
    new_index = rem(state.message_index + 1, length(@messages))
    schedule_message_cycle()
    {:noreply, %{state | message_index: new_index}}
  end

  # Private Functions

  defp schedule_frame do
    Process.send_after(self(), :tick, @frame_rate)
  end

  defp schedule_message_cycle do
    Process.send_after(self(), :cycle_message, @message_cycle_ms)
  end

  defp advance_frame(state) do
    frame_index = rem(state.frame_index + 1, length(@frames))

    color_index =
      if frame_index == 0,
        do: rem(state.color_index + 1, length(@colors)),
        else: state.color_index

    # Advance text pulse every frame for smooth gradient
    text_pulse_index = rem(state.text_pulse_index + 1, length(@text_pulse_colors))

    %{
      state
      | frame_index: frame_index,
        color_index: color_index,
        text_pulse_index: text_pulse_index
    }
  end

  defp render(state) do
    frame = Enum.at(@frames, state.frame_index)
    spinner_color = Enum.at(@colors, state.color_index)
    {r, g, b} = Enum.at(@text_pulse_colors, state.text_pulse_index)
    message = state.message || Enum.at(@messages, state.message_index)

    # Single write with cursor reset + content + clear to EOL to avoid flicker
    # Uses 256-color for spinner, 24-bit true color for text gradients
    IO.write([
      "\r",
      " ",
      "\e[38;5;#{spinner_color}m",
      frame,
      IO.ANSI.reset(),
      " ",
      "\e[38;2;#{r};#{g};#{b}m",
      message,
      "...",
      IO.ANSI.reset(),
      "\e[K"
    ])
  end

  defp render_final(:success, message) do
    IO.puts([
      " ",
      IO.ANSI.green(),
      "✓",
      IO.ANSI.reset(),
      " ",
      IO.ANSI.cyan(),
      message,
      IO.ANSI.reset()
    ])
  end

  defp render_final(:failure, message) do
    IO.puts([
      " ",
      IO.ANSI.red(),
      "✗",
      IO.ANSI.reset(),
      " ",
      IO.ANSI.magenta(),
      message,
      IO.ANSI.reset()
    ])
  end

  defp clear_line do
    IO.write(["\r", IO.ANSI.clear_line()])
  end
end
