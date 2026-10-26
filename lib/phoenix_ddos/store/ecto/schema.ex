if Code.ensure_loaded?(Ecto.Schema) do
  defmodule PhoenixDDoS.Store.Ecto.Schema do
    @moduledoc false

    use Ecto.Schema

    schema "phoenix_ddos_bans" do
      field(:ip, :string)
      field(:reason, :string)
      field(:protection, :string)
      field(:banned_at, :utc_datetime_usec)
      field(:expires_at, :utc_datetime_usec)
      field(:released_at, :utc_datetime_usec)
      field(:metadata, :map, default: %{})
    end
  end
end
