defmodule PhoenixDDoS.IP do
  @moduledoc false

  # Client identity used everywhere (rate limits, jail, safelist, blocklist):
  #  - IPv4: dotted form
  #  - IPv4-mapped IPv6 (::ffff:a.b.c.d): same as the IPv4 form
  #  - IPv6: bucketed by prefix (`:ipv6_prefix`, default 64), e.g. 2001:db8::/64

  import Bitwise

  @default_prefix 64

  @spec key(:inet.ip_address()) :: charlist
  def key({_, _, _, _} = ip), do: ntoa(ip)

  def key({0, 0, 0, 0, 0, 0xFFFF, hi, lo}) do
    ntoa({hi >>> 8, hi &&& 0xFF, lo >>> 8, lo &&& 0xFF})
  end

  def key({_, _, _, _, _, _, _, _} = ip) do
    prefix = prefix()
    network = ip |> to_integer() |> band(mask(prefix)) |> from_integer()
    ntoa(network) ++ ~c"/" ++ Integer.to_charlist(prefix)
  end

  @spec normalize!(String.t() | charlist) :: charlist
  def normalize!(ip) when is_binary(ip), do: ip |> String.to_charlist() |> normalize!()

  def normalize!(ip) when is_list(ip) do
    case :inet.parse_address(ip) do
      {:ok, address} -> key(address)
      {:error, _} -> raise ArgumentError, "invalid IP address: #{inspect(to_string(ip))}"
    end
  end

  # For lookups by callers (e.g. PhoenixDDoS.Jail): an address (tuple, string
  # or charlist) becomes its key; anything else, such as an already normalized
  # prefix key like "2001:db8::/64", is returned unchanged as a charlist.
  @spec lookup_key(:inet.ip_address() | String.t() | charlist) :: charlist
  def lookup_key(ip) when is_tuple(ip), do: key(ip)
  def lookup_key(ip) when is_binary(ip), do: ip |> String.to_charlist() |> lookup_key()

  def lookup_key(ip) when is_list(ip) do
    case :inet.parse_address(ip) do
      {:ok, address} -> key(address)
      {:error, _} -> ip
    end
  end

  defp ntoa(ip) do
    case :inet.ntoa(ip) do
      {:error, _} -> raise ArgumentError, "invalid IP address: #{inspect(ip)}"
      chars -> chars
    end
  end

  defp prefix do
    case Application.get_env(:phoenix_ddos, :ipv6_prefix, @default_prefix) do
      p when is_integer(p) and p in 0..128 ->
        p

      other ->
        raise ArgumentError, ":ipv6_prefix must be an integer in 0..128, got: #{inspect(other)}"
    end
  end

  defp mask(prefix), do: ((1 <<< prefix) - 1) <<< (128 - prefix)

  defp to_integer(ip) do
    ip |> Tuple.to_list() |> Enum.reduce(0, fn group, acc -> acc <<< 16 ||| group end)
  end

  defp from_integer(int) do
    for(shift <- 112..0//-16, do: int >>> shift &&& 0xFFFF) |> List.to_tuple()
  end
end
