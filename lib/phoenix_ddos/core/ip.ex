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

  # an address (tuple, string or charlist) or a key, as its key
  @spec normalize!(:inet.ip_address() | String.t() | charlist) :: charlist
  def normalize!(ip) when is_tuple(ip), do: key(ip)

  def normalize!(ip) do
    entry = ip |> to_string() |> String.trim()

    case parse_entry(entry) do
      {:ok, address} -> key(address)
      _ -> raise ArgumentError, "invalid IP address: #{inspect(entry)}"
    end
  end

  # an address, or an IPv6 key as produced by key/1 (e.g. "2001:db8::/64" from
  # jail telemetry), bucketed again by the current ipv6_prefix.
  # IPv4 ranges ("1.2.3.0/24") are not supported.
  defp parse_entry(entry) do
    case String.split(entry, "/") do
      [address] -> :inet.parse_address(to_charlist(address))
      [address, _length] -> :inet.parse_ipv6strict_address(to_charlist(address))
      _ -> :error
    end
  end

  defp ntoa(ip) do
    case :inet.ntoa(ip) do
      {:error, _} -> raise ArgumentError, "invalid IP address: #{inspect(ip)}"
      chars -> chars
    end
  end

  # validated at startup by PhoenixDDoS.Configure
  defp prefix, do: Application.get_env(:phoenix_ddos, :ipv6_prefix, @default_prefix)

  defp mask(prefix), do: ((1 <<< prefix) - 1) <<< (128 - prefix)

  defp to_integer(ip) do
    ip |> Tuple.to_list() |> Enum.reduce(0, fn group, acc -> acc <<< 16 ||| group end)
  end

  defp from_integer(int) do
    for(shift <- 112..0//-16, do: int >>> shift &&& 0xFFFF) |> List.to_tuple()
  end
end
