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

defmodule PhoenixDDoS.CountingRouter do
  @moduledoc false
  # delegates to PhoenixDDoS.Router, counting route resolutions in the process dictionary

  def __match_route__(path, method, host) do
    Process.put(:counting_router_calls, calls() + 1)
    PhoenixDDoS.Router.__match_route__(path, method, host)
  end

  def calls, do: Process.get(:counting_router_calls, 0)
end
