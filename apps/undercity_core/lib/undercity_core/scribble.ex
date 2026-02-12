defmodule UndercityCore.Scribble do
  @moduledoc """
  Sanitisation for scribble text written on blocks.
  """

  @max_length 80

  @doc """
  Sanitises scribble text by stripping invalid characters and truncating.
  Returns `{:ok, text}` or `:empty` if nothing remains.
  """
  @spec sanitise(String.t()) :: {:ok, String.t()} | :empty
  def sanitise(text) when is_binary(text) do
    sanitised =
      text
      |> String.replace(~r/[^a-zA-Z0-9 ]/, "")
      |> String.trim()
      |> String.slice(0, @max_length)

    if sanitised == "" do
      :empty
    else
      {:ok, sanitised}
    end
  end
end
