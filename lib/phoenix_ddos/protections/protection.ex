defmodule PhoenixDDOS.Protection do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias PhoenixDDOS.RateLimit
      alias PhoenixDDOS.Time
    end
  end
end
