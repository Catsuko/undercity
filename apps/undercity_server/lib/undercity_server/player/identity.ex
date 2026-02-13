defmodule UndercityServer.Player.Identity do
  @moduledoc """
  Owns player identity concerns: ID generation and process naming.

  Generates unique hex IDs for new players and maps player IDs to
  process names for GenServer registration and lookup.
  """

  @doc """
  Generates a unique player ID.
  """
  @spec generate_id() :: String.t()
  def generate_id do
    8 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
  end

  @doc """
  Returns the process name for a player GenServer.
  """
  @spec via(String.t()) :: atom()
  def via(player_id) do
    :"player_#{player_id}"
  end
end
