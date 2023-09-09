defmodule PhoenixDDOS.Protection do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias PhoenixDDOS.Cache
      alias PhoenixDDOS.Config
    end
  end
end
