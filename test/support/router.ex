# dummy router/controller
defmodule AController do
  @moduledoc false
  use Phoenix.Controller
end

defmodule PhoenixDDoS.EmptyRouter do
  @moduledoc false
  use Phoenix.Router
end

defmodule PhoenixDDoS.Router do
  @moduledoc false
  use Phoenix.Router

  scope "/" do
    get("/", AController, :home)
    get("/admin", AController, :home)
    get("/admin/:id/dashboard", AController, :home)
    post("/admin", AController, :home)
    get("/user", AController, :home)
  end
end
