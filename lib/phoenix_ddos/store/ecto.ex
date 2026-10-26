if Code.ensure_loaded?(Ecto.Query) do
  defmodule PhoenixDDoS.Store.Ecto do
    @moduledoc """
    Keep the bans in your database through Ecto: postgres, mysql, sqlite, whatever your repo runs on.

    1. `ecto_sql` in your deps, if not already there
    2. a migration creating the table:

            defmodule MyApp.Repo.Migrations.AddPhoenixDdosBans do
              use Ecto.Migration

              def up, do: PhoenixDDoS.Store.Ecto.Migration.up()
              def down, do: PhoenixDDoS.Store.Ecto.Migration.down()
            end

    3. the config:

            config :phoenix_ddos, store: {PhoenixDDoS.Store.Ecto, repo: MyApp.Repo}

    Options:

    * `:repo` - required
    * `:table` - table name, default `"phoenix_ddos_bans"`, must match the migration
    * `:repo_opts` - options given to every repo call, default `[]`. Ex: `[prefix: "ddos"]`,
      `[log: false]`

    `PhoenixDDoS.Ban` `:metadata` is stored as a map (jsonb on postgres): wrap this store to fill
    it with your own data, see `PhoenixDDoS.Store`.
    """

    @behaviour PhoenixDDoS.Store

    import Ecto.Query

    alias PhoenixDDoS.Ban
    alias PhoenixDDoS.Store.Ecto.Schema

    @impl true
    def init(opts) do
      case Keyword.fetch(opts, :repo) do
        {:ok, repo} ->
          {:ok,
           %{
             repo: repo,
             table: Keyword.get(opts, :table, "phoenix_ddos_bans"),
             repo_opts: Keyword.get(opts, :repo_opts, [])
           }}

        :error ->
          {:error, "PhoenixDDoS.Store.Ecto: :repo option is required"}
      end
    end

    @impl true
    def insert_ban(%{repo: repo, table: table, repo_opts: repo_opts}, %Ban{} = ban, _conn) do
      %Schema{
        ip: ban.ip,
        reason: ban.reason,
        protection: ban.protection,
        banned_at: ban.banned_at,
        expires_at: ban.expires_at,
        released_at: ban.released_at,
        metadata: ban.metadata
      }
      |> Ecto.put_meta(source: table)
      |> repo.insert(repo_opts)
    end

    @impl true
    def release_ban(%{repo: repo, table: table, repo_opts: repo_opts}, ip, released_at) do
      from(b in {table, Schema},
        where:
          b.ip == ^ip and is_nil(b.released_at) and
            (is_nil(b.expires_at) or b.expires_at > ^released_at)
      )
      |> repo.update_all([set: [released_at: released_at]], repo_opts)

      :ok
    end

    @impl true
    def active_bans(%{repo: repo, table: table, repo_opts: repo_opts}, now) do
      bans =
        from(b in {table, Schema},
          where: is_nil(b.released_at) and (is_nil(b.expires_at) or b.expires_at > ^now),
          order_by: [asc: b.banned_at]
        )
        |> repo.all(repo_opts)
        |> Enum.map(&to_ban/1)

      {:ok, bans}
    end

    defp to_ban(%Schema{} = row) do
      %Ban{
        ip: row.ip,
        reason: row.reason,
        protection: row.protection,
        banned_at: row.banned_at,
        expires_at: row.expires_at,
        released_at: row.released_at,
        metadata: row.metadata || %{}
      }
    end
  end
end
