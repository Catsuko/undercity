defmodule UndercityServer.PlayerIdentity do
  @moduledoc """
  Owns player identity concerns: ID generation, process lookup, and name resolution.
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
