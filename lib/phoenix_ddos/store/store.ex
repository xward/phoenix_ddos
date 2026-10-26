defmodule PhoenixDDoS.Store do
  @moduledoc """
  Behaviour to persist bans outside the node: in your database, in redis, anywhere.

  Without a store (the default) nothing changes: the jail lives in memory and a restart empties
  it. With one:

  * every ban and every bail out is written to it, in the background
  * at boot, the bans still active in the store are put back in jail

  The jail in memory stays the only thing consulted on the request path: a slow or failing store
  never slows down a request, it only logs an error and emits `[:phoenix_ddos, :store, :error]`.
  Every callback runs in one process, `PhoenixDDoS.Store.Server`.

  ## In your database

  `PhoenixDDoS.Store.Ecto` ships with the library:

      config :phoenix_ddos, store: {PhoenixDDoS.Store.Ecto, repo: MyApp.Repo}

  ## Your own code: the user behind the ip, a note...

  `c:insert_ban/3` receives the `Plug.Conn` of the request that got the ip jailed (`nil` for a
  ban sent from the console), so a store can record anything that request knows. The shortest
  way is to wrap the Ecto store and fill `PhoenixDDoS.Ban` `:metadata`, stored as a map (jsonb
  on postgres):

      defmodule MyApp.BanStore do
        @behaviour PhoenixDDoS.Store

        alias PhoenixDDoS.Store.Ecto

        @impl true
        defdelegate init(opts), to: Ecto
        @impl true
        defdelegate release_ban(state, ip, released_at), to: Ecto
        @impl true
        defdelegate active_bans(state, now), to: Ecto

        @impl true
        def insert_ban(state, ban, %Plug.Conn{} = conn) do
          metadata = %{
            user_id: MyApp.Accounts.user_id_from_session(conn),
            user_agent: conn |> Plug.Conn.get_req_header("user-agent") |> List.first(),
            note: "caught on \#{conn.request_path}"
          }

          Ecto.insert_ban(state, %{ban | metadata: metadata}, conn)
        end

        def insert_ban(state, ban, nil), do: Ecto.insert_ban(state, ban, nil)
      end

      config :phoenix_ddos, store: {MyApp.BanStore, repo: MyApp.Repo}

  Or implement the four callbacks from scratch, over whatever you want. Keep in mind the plug
  usually sits in the endpoint, before the router: `conn.assigns` is not filled yet at that
  point, the session and the headers are what the request knows.
  """

  alias PhoenixDDoS.Ban

  @type state :: term()

  @doc "Called once at boot with the options given in the config. The state is given to every other callback."
  @callback init(opts :: keyword()) :: {:ok, state()} | {:error, term()}

  @doc "Persist a new ban. `conn` is the request that got the ip jailed, `nil` when there is none."
  @callback insert_ban(state(), Ban.t(), Plug.Conn.t() | nil) ::
              :ok | {:ok, term()} | {:error, term()}

  @doc "The ip was bailed out at `released_at`: mark its active bans as released."
  @callback release_ban(state(), ip :: String.t(), released_at :: DateTime.t()) ::
              :ok | {:error, term()}

  @doc "Every ban still active at `now`: not released and not expired. They go back to jail at boot."
  @callback active_bans(state(), now :: DateTime.t()) :: {:ok, [Ban.t()]} | {:error, term()}
end
