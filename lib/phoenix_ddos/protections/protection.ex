defmodule PhoenixDDoS.Protection do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias PhoenixDDoS.RateLimit
      alias PhoenixDDoS.RequestPath
      alias PhoenixDDoS.Time
    end
  end
end
