defmodule PhoenixDDoS.RequestPath do
  @moduledoc false

  def match?(id, path) when is_binary(path) do
    __MODULE__.match?(id, String.split(path, "/"))
  end

  def match?(_, _), do: false
end
