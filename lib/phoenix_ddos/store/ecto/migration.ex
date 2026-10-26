if Code.ensure_loaded?(Ecto.Migration) do
  defmodule PhoenixDDoS.Store.Ecto.Migration do
    @moduledoc """
    Creates the bans table. Call it from a migration of yours, see `PhoenixDDoS.Store.Ecto`.
    `:table` (default `"phoenix_ddos_bans"`) must match the store option.
    """

    use Ecto.Migration

    @default_table "phoenix_ddos_bans"

    def up(opts \\ []) do
      table = Keyword.get(opts, :table, @default_table)

      create_if_not_exists table(table) do
        add(:ip, :string, null: false)
        add(:reason, :text)
        add(:protection, :string)
        add(:banned_at, :utc_datetime_usec, null: false)
        add(:expires_at, :utc_datetime_usec)
        add(:released_at, :utc_datetime_usec)
        add(:metadata, :map)
      end

      create_if_not_exists(index(table, [:ip]))
      # active bans lookup at boot: released_at is null and expires_at > now
      create_if_not_exists(index(table, [:released_at, :expires_at]))
    end

    def down(opts \\ []) do
      drop_if_exists(table(Keyword.get(opts, :table, @default_table)))
    end
  end
end
