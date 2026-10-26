defmodule PhoenixDDoS.Ban do
  @moduledoc """
  An ip sent to jail: what the jail holds in memory and what a `PhoenixDDoS.Store` persists.

  * `:ip` - the banned ip, as a string (`"1.2.3.4"`)
  * `:reason` - human readable, built from the protection that caught the ip
  * `:protection` - module name of that protection (`"PhoenixDDoS.IpRateLimit"`)
  * `:banned_at` - when the ban started
  * `:expires_at` - when it ends, `nil` for a ban that lasts until the ip is bailed out
  * `:released_at` - set in the store when the ip was bailed out before `:expires_at`
  * `:metadata` - free map for your own store: the user behind the ip, a note... Empty unless
    your store fills it, see `PhoenixDDoS.Store`
  """

  alias PhoenixDDoS.Time

  @type t :: %__MODULE__{
          ip: String.t(),
          reason: String.t(),
          protection: String.t() | nil,
          banned_at: DateTime.t(),
          expires_at: DateTime.t() | nil,
          released_at: DateTime.t() | nil,
          metadata: map()
        }

  defstruct ip: nil,
            reason: nil,
            protection: nil,
            banned_at: nil,
            expires_at: nil,
            released_at: nil,
            metadata: %{}

  @doc false
  def new(ip, {module, cfg}) do
    now = Time.now()

    %__MODULE__{
      ip: to_string(ip),
      reason: reason(module, cfg),
      protection: module && inspect(module),
      banned_at: now,
      expires_at: DateTime.add(now, Time.period_to_msec(cfg.jail_time), :millisecond)
    }
  end

  @doc "true when the ban is still in effect at `now`"
  @spec active?(t(), DateTime.t()) :: boolean()
  def active?(%__MODULE__{released_at: released_at}, _now) when not is_nil(released_at), do: false
  def active?(%__MODULE__{expires_at: nil}, _now), do: true

  def active?(%__MODULE__{expires_at: expires_at}, now),
    do: DateTime.compare(expires_at, now) == :gt

  @doc "remaining jail time in milliseconds at `now`, `nil` when the ban never expires"
  @spec remaining_ms(t(), DateTime.t()) :: non_neg_integer() | nil
  def remaining_ms(%__MODULE__{expires_at: nil}, _now), do: nil

  def remaining_ms(%__MODULE__{expires_at: expires_at}, now),
    do: max(DateTime.diff(expires_at, now, :millisecond), 0)

  defp reason(nil, _cfg), do: "sent to jail"

  defp reason(module, cfg) do
    on = if cfg[:request_paths], do: " on #{inspect(cfg.request_paths)}", else: ""
    {n, unit} = cfg.period
    "#{inspect(module)}: more than #{cfg.allowed} requests#{on} in #{n} #{unit}"
  end
end
