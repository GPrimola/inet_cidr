defmodule InetCidr do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  import Bitwise

  @type ip_address :: :inet.ip_address()

  @type prefix_length_v4 :: 0..32
  @type prefix_length_v6 :: 0..128
  @type prefix_length :: prefix_length_v4() | prefix_length_v6()

  @type cidr4 ::
          {start_address :: :inet.ip4_address(), end_address :: :inet.ip4_address(),
           prefix_length_v4()}
  @type cidr6 ::
          {start_address :: :inet.ip6_address(), end_address :: :inet.ip6_address(),
           prefix_length_v6()}
  @type cidr :: cidr4() | cidr6()

  @doc """
  Parses a string containing either an IPv4 or IPv6 CIDR block using the
  notation like `192.168.0.0/16` or `2001:abcd::/32`. It returns a tuple with the
  start address, end address and cidr length.

  You can optionally pass true as the second argument to adjust the start `IP`
  address if it is not consistent with the cidr length.
  For example, `192.168.0.0/0` would be adjusted to have a start IP of `0.0.0.0`
  instead of `192.168.0.0`. The default behavior is to be more strict and raise
  an exception when this occurs.
  """
  @deprecated "Use `parse_cidr!/2` instead (or `parse_cidr/2` for {:ok, {start,end,prefix}} / {:error,msg} tuples)"
  @spec parse(cidr_string :: String.t(), adjust :: boolean()) :: cidr()
  def parse(cidr_string, adjust \\ false) do
    {start_address, prefix_length} = parse_cidr_block!(cidr_string, adjust)
    end_address = calc_end_address!(start_address, prefix_length)
    {start_address, end_address, prefix_length}
  end

  @doc since: "1.0.6"
  @doc """
  Parses a string containing either an IPv4 or IPv6 CIDR block using the
  notation like `192.168.0.0/16` or `2001:abcd::/32`.

  You can optionally pass true as the second argument to adjust the start `IP`
  address if it is not consistent with the cidr length.
  For example, `192.168.0.0/0` would be adjusted to have a start IP of `0.0.0.0`
  instead of `192.168.0.0`.

  It returns an `{:ok, {start address, end address, cidr length}}` tuple if the string contains a valid IP address.

  It returns an `{:error, reason}` tuple if the it cannot be parsed.
  """
  @spec parse_cidr(cidr_string :: String.t(), adjust :: boolean()) ::
          {:ok, cidr()} | {:error, reason :: any()}
  def parse_cidr(cidr_string, adjust \\ false) do
    try do
      {:ok, parse_cidr!(cidr_string, adjust)}
    rescue
      e ->
        case e do
          err -> {:error, err}
        end
    end
  end

  @doc since: "1.0.6"
  @doc """
  Parses a string containing either an IPv4 or IPv6 CIDR block using the
  notation like `192.168.0.0/16` or `2001:abcd::/32`. It returns a tuple with the
  start address, end address and cidr length.

  You can optionally pass true as the second argument to adjust the start `IP`
  address if it is not consistent with the cidr length.
  For example, `192.168.0.0/0` would be adjusted to have a start IP of `0.0.0.0`
  instead of `192.168.0.0`. The default behavior is to be more strict and raise
  an exception when this occurs.
  """
  @spec parse_cidr!(cidr_string :: String.t(), adjust :: boolean()) :: cidr()
  def parse_cidr!(cidr_string, adjust \\ false) do
    parse(cidr_string, adjust)
  end

  @doc since: "1.0.6"
  @doc """
  Convenience function that takes an IPv4 or IPv6 address as a string and
  returns the address.

  It returns an `{:ok, address}` tuple if the string contains a valid IP address.

  It returns an `{:error, reason}` tuple if the string
  does not contain a valid IP address.
  """
  @spec parse_address(ip_addr :: String.t()) :: {:ok, ip_address()} | {:error, reason :: any()}
  def parse_address(address_str) do
    try do
      {:ok, parse_address!(address_str)}
    rescue
      e ->
        case e do
          err -> {:error, err}
        end
    end
  end

  @doc since: "1.0.6"
  @doc """
  Convenience function that takes an IPv4 or IPv6 address as a string and
  returns the address.  It raises an exception if the string does not contain
  a valid IP address.
  """
  @spec parse_address!(ip_addr :: String.t()) :: ip_address()
  def parse_address!(address_str) do
    case address_str |> String.to_charlist() |> :inet.parse_address() do
      {:ok, start_address} -> start_address
      {:error, _} -> raise "Invalid address: #{address_str}"
    end
  end

  @doc """
  Prints the CIDR block to a string such that it can be parsed back to a CIDR
  block by this module.
  """
  @spec to_string(cidr()) :: String.t()
  def to_string({start_address, _end_address, cidr_length}) do
    "#{:inet.ntoa(start_address)}/#{cidr_length}"
  end

  @doc """
  The number of IP addresses included in the CIDR block.
  """
  @spec address_count(ip_address(), prefix_length()) :: non_neg_integer()
  def address_count(ip, len) do
    1 <<< (bit_count(ip) - len)
  end

  @doc """
  The number of bits in the address family (32 for IPv4 and 128 for IPv6)
  """
  @spec bit_count(ip_address()) :: 32 | 128
  def bit_count({_, _, _, _}), do: 32
  def bit_count({_, _, _, _, _, _, _, _}), do: 128

  @doc """
  Returns true if the CIDR block contains the IP address, false otherwise.
  """
  @spec contains?(cidr(), ip_address()) :: boolean()
  def contains?({{a, b, c, d}, {e, f, g, h}, _prefix_length}, {w, x, y, z}) do
    w in a..e and
      x in b..f and
      y in c..g and
      z in d..h
  end

  def contains?(
        {{a, b, c, d, e, f, g, h}, {i, j, k, l, m, n, o, p}, _prefix_length},
        {r, s, t, u, v, w, x, y}
      ) do
    r in a..i and
      s in b..j and
      t in c..k and
      u in d..l and
      v in e..m and
      w in f..n and
      x in g..o and
      y in h..p
  end

  def contains?(_, _), do: false

  @doc """
  Returns true if the value passed in is an IPv4 address, false otherwise.
  """
  @spec v4?(ip_address()) :: boolean()
  def v4?({a, b, c, d}) when a in 0..255 and b in 0..255 and c in 0..255 and d in 0..255, do: true
  def v4?(_), do: false

  @doc """
  Returns true if the value passed in is an IPv6 address, false otherwise.
  """
  @spec v6?(ip_address()) :: boolean()
  def v6?({a, b, c, d, e, f, g, h})
      when a in 0..65535 and b in 0..65535 and c in 0..65535 and d in 0..65535 and e in 0..65535 and
             f in 0..65535 and g in 0..65535 and h in 0..65535,
      do: true

  def v6?(_), do: false

  @doc """
  Returns true if CIDR1 and CIDR2 have no addresses in common (no overlap).
  """
  @spec disjoint?(cidr(), cidr()) :: boolean()
  def disjoint?(
        {start_address1, _end_address1, _len1} = cidr1,
        {start_address2, _end_address2, _len2} = cidr2
      ),
      do: not contains?(cidr1, start_address2) and not contains?(cidr2, start_address1)

  @doc since: "1.0.7"
  @doc """
  Calculates the end of a CIDR block given the start address (tuple) and prefix length.

  Returns an `{:ok, end_address}` tuple if the start address and prefix length are valid.
  Returns {:error, reason} if the start address or prefix length are invalid.
  """
  @spec calc_end_address(ip_address(), prefix_length()) ::
          {:ok, ip_address()} | {:error, reason :: any()}
  def calc_end_address(start_address, prefix_length) do
    try do
      {:ok, calc_end_address!(start_address, prefix_length)}
    rescue
      e ->
        case e do
          err -> {:error, err}
        end
    end
  end

  @doc since: "1.0.7"
  @doc """
  Calculates the end of a CIDR block given the start address (tuple) and prefix length.

  Assumes valid start address and prefix length. Raises an exception if either is invalid.
  """
  @spec calc_end_address!(ip_address(), prefix_length()) :: ip_address()
  def calc_end_address!(start_address, prefix_length) do
    bor_with_mask(start_address, end_mask(start_address, prefix_length))
  end

  #
  # internal functions
  #

  @spec parse_cidr_block!(cidr_string :: String.t(), adjust :: boolean()) ::
          {ip_address(), prefix_length()}
  defp parse_cidr_block!(cidr_string, adjust) do
    [prefix, prefix_length_str] = String.split(cidr_string, "/", parts: 2)
    start_address = parse_address!(prefix)
    {prefix_length, _} = Integer.parse(prefix_length_str)
    # if something 'nonsensical' is passed in like 192.168.0.0/0
    # we have three choices:
    # a) leave it alone (we do NOT allow this)
    # b) adjust the start ip (to 0.0.0.0 in this case) - when adjust == true
    # c) raise an exception - when adjust != true
    masked = band_with_mask(start_address, start_mask(start_address, prefix_length))

    if not adjust and masked != start_address do
      raise "Invalid CIDR: #{cidr_string}"
    end

    {masked, prefix_length}
  end

  @spec start_mask(ip_address(), prefix_length()) :: ip_address()
  defp start_mask(s = {_, _, _, _}, len) when len in 0..32 do
    {a, b, c, d} = end_mask(s, len)

    a = a |> bnot() |> abs()
    b = b |> bnot() |> abs()
    c = c |> bnot() |> abs()
    d = d |> bnot() |> abs()

    {a, b, c, d}
  end

  defp start_mask(s = {_, _, _, _, _, _, _, _}, len) when len in 0..128 do
    {a, b, c, d, e, f, g, h} = end_mask(s, len)

    a = a |> bnot() |> abs()
    b = b |> bnot() |> abs()
    c = c |> bnot() |> abs()
    d = d |> bnot() |> abs()
    e = e |> bnot() |> abs()
    f = f |> bnot() |> abs()
    g = g |> bnot() |> abs()
    h = h |> bnot() |> abs()

    {a, b, c, d, e, f, g, h}
  end

  @spec end_mask(ip_address(), prefix_length()) :: ip_address()
  defp end_mask({_, _, _, _}, len) when len in 0..32 do
    cond do
      len == 32 -> {0, 0, 0, 0}
      len >= 24 -> {0, 0, 0, bmask(len, 8)}
      len >= 16 -> {0, 0, bmask(len, 8), 0xFF}
      len >= 8 -> {0, bmask(len, 8), 0xFF, 0xFF}
      len >= 0 -> {bmask(len, 8), 0xFF, 0xFF, 0xFF}
    end
  end

  defp end_mask({_, _, _, _, _, _, _, _}, len) when len in 0..128 do
    cond do
      len == 128 -> {0, 0, 0, 0, 0, 0, 0, 0}
      len >= 112 -> {0, 0, 0, 0, 0, 0, 0, bmask(len, 16)}
      len >= 96 -> {0, 0, 0, 0, 0, 0, bmask(len, 16), 0xFFFF}
      len >= 80 -> {0, 0, 0, 0, 0, bmask(len, 16), 0xFFFF, 0xFFFF}
      len >= 64 -> {0, 0, 0, 0, bmask(len, 16), 0xFFFF, 0xFFFF, 0xFFFF}
      len >= 48 -> {0, 0, 0, bmask(len, 16), 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF}
      len >= 32 -> {0, 0, bmask(len, 16), 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF}
      len >= 16 -> {0, bmask(len, 16), 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF}
      len >= 0 -> {bmask(len, 16), 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF}
    end
  end

  defp bmask(i, 8) when i in 0..32 do
    0xFF >>> rem(i, 8)
  end

  defp bmask(i, 16) when i in 0..128 do
    0xFFFF >>> rem(i, 16)
  end

  defp bor_with_mask({a, b, c, d}, {e, f, g, h}) do
    {bor(a, e), bor(b, f), bor(c, g), bor(d, h)}
  end

  defp bor_with_mask({a, b, c, d, e, f, g, h}, {i, j, k, l, m, n, o, p}) do
    {bor(a, i), bor(b, j), bor(c, k), bor(d, l), bor(e, m), bor(f, n), bor(g, o), bor(h, p)}
  end

  defp band_with_mask({a, b, c, d}, {e, f, g, h}) do
    {band(a, e), band(b, f), band(c, g), band(d, h)}
  end

  defp band_with_mask({a, b, c, d, e, f, g, h}, {i, j, k, l, m, n, o, p}) do
    {band(a, i), band(b, j), band(c, k), band(d, l), band(e, m), band(f, n), band(g, o),
     band(h, p)}
  end
end
