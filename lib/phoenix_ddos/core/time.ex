defmodule PhoenixDDOS.Time do
  @moduledoc """
  Time helper
  """

  def now, do: DateTime.utc_now()
  def diff_ms(%DateTime{} = start), do: DateTime.diff(now(), start, :millisecond)

  def period_to_msec({n, :second}), do: :timer.seconds(n)
  def period_to_msec({n, :minute}), do: :timer.minutes(n)
  def period_to_msec({n, :hour}), do: :timer.hours(n)
  def period_to_msec({n, :day}), do: :timer.hours(n) * 24
  def period_to_msec(period), do: raise("Invalid configuration period #{period}")
end
