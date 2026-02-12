defmodule UndercityCore.Scribble do
  @moduledoc """
  Validation for scribble text written on blocks.
  """

  @max_length 80

  @spec validate(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def validate(text) when is_binary(text) do
    cond do
      String.length(text) == 0 ->
        {:error, "scribble cannot be empty"}

      String.length(text) > @max_length ->
        {:error, "scribble must be #{@max_length} characters or fewer"}

      not Regex.match?(~r/^[a-zA-Z0-9 ]+$/, text) ->
        {:error, "scribble can only contain letters, numbers, and spaces"}

      true ->
        {:ok, text}
    end
  end
end
