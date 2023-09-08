defmodule PhoenixDDOS do
  @moduledoc """
  Documentation for `PhoenixDDOS`.
  """

  @behaviour Plug

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(conn, _opts) do
    conn
  end

end
