defmodule UndercityCli.View.Constitution do
  @moduledoc """
  AP and HP tier logic with status and threshold messages.
  """

  alias UndercityCli.View.Status

  @doc """
  Renders the current AP/HP status as formatted message lines.
  When collapsed (hp=0), only shows health status.
  """
  def render(_ap, 0) do
    {text, category} = health_status_message(0)
    Status.format_message(text, category)
  end

  def render(ap, hp) do
    {ap_text, ap_cat} = status_message(ap)
    {hp_text, hp_cat} = health_status_message(hp)

    Enum.join([Status.format_message(ap_text, ap_cat), Status.format_message(hp_text, hp_cat)], "\n")
  end

  @doc """
  Returns the awareness tier for a given AP value.
  """
  def awareness_tier(0), do: :spent
  def awareness_tier(ap) when ap >= 40, do: :rested
  def awareness_tier(ap) when ap >= 16, do: :weary
  def awareness_tier(_ap), do: :exhausted

  @doc """
  Returns a status message for the current AP tier.
  """
  def status_message(ap), do: tier_message(awareness_tier(ap))

  @doc """
  Returns a threshold crossing message if AP dropped into a new tier, or nil.
  """
  def threshold_message(old_ap, new_ap) do
    old_tier = awareness_tier(old_ap)
    new_tier = awareness_tier(new_ap)

    if old_tier != new_tier do
      tier_message(new_tier)
    end
  end

  defp tier_message(:rested), do: {"You feel rested.", :success}
  defp tier_message(:weary), do: {"You feel weary.", :warning}
  defp tier_message(:exhausted), do: {"You can barely keep your eyes open.", :warning}
  defp tier_message(:spent), do: {"You are completely exhausted.", :warning}

  @doc """
  Returns the health tier for a given HP value.
  """
  def health_tier(0), do: :collapsed
  def health_tier(hp) when hp >= 45, do: :healthy
  def health_tier(hp) when hp >= 35, do: :sore
  def health_tier(hp) when hp >= 15, do: :wounded
  def health_tier(hp) when hp >= 5, do: :battered
  def health_tier(_hp), do: :critical

  @doc """
  Returns a status message for the current health tier.
  """
  def health_status_message(hp), do: health_tier_message(health_tier(hp))

  @doc """
  Returns a threshold crossing message if HP moved into a new tier, or nil.
  """
  def health_threshold_message(old_hp, new_hp) do
    old_tier = health_tier(old_hp)
    new_tier = health_tier(new_hp)

    if old_tier != new_tier do
      health_tier_message(new_tier)
    end
  end

  defp health_tier_message(:healthy), do: {"You feel healthy.", :success}
  defp health_tier_message(:sore), do: {"You feel some aches and pains.", :warning}
  defp health_tier_message(:wounded), do: {"You are wounded.", :warning}
  defp health_tier_message(:battered), do: {"You are severely wounded.", :warning}
  defp health_tier_message(:critical), do: {"You have many wounds and are close to passing out.", :warning}
  defp health_tier_message(:collapsed), do: {"Your body has given out.", :warning}
end
