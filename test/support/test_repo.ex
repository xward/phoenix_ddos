defmodule PhoenixDDoS.TestRepo do
  @moduledoc false
  use Ecto.Repo, otp_app: :phoenix_ddos, adapter: Ecto.Adapters.SQLite3
end

defmodule PhoenixDDoS.TestRepo.Migrations.AddPhoenixDdosBans do
  @moduledoc false
  use Ecto.Migration

  def up, do: PhoenixDDoS.Store.Ecto.Migration.up()
  def down, do: PhoenixDDoS.Store.Ecto.Migration.down()
end
