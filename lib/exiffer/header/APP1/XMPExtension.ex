defmodule Exiffer.Header.APP1.XMPExtension do
  @moduledoc """
  Documentation for `Exiffer.Header.APP1.XMPExtension`.
  """

  alias Exiffer.Binary
  alias Exiffer.IO.Buffer
  require Logger

  @header "http://ns.adobe.com/xmp/extension/\0"

  @enforce_keys ~w(xpacket)a
  defstruct ~w(xpacket)a

  defimpl Jason.Encoder  do
    @spec encode(%Exiffer.Header.APP1.XMPExtension{}, Jason.Encode.opts()) :: String.t()
    def encode(entry, opts) do
      Jason.Encode.map(
        %{
          module: "Exiffer.Header.APP1.XMPExtension",
          xpacket: "(#{byte_size(entry.xpacket)} bytes)",
        },
        opts
      )
    end
  end

  def new(%{data: <<length_bytes::binary-size(2), @header::binary, _rest::binary>>} = buffer) do
    length = Binary.big_endian_to_integer(length_bytes)
    header_length = String.length(@header)
    buffer = Buffer.skip(buffer, 2 + header_length)
    xpacket_length = length - 2 - header_length
    {xpacket, buffer} = Buffer.consume(buffer, xpacket_length)
    xmp = %__MODULE__{xpacket: xpacket}
    {xmp, buffer}
  end

  def puts(%__MODULE__{} = xmp) do
    truncated = if String.length(xmp.xpacket) > 47 do
      "#{String.slice(xmp.xpacket, 0, 47)}..."
    else
      xmp.xpacket
    end
    IO.puts "XPacket"
    IO.puts "-------"
    IO.puts truncated
    :ok
  end

  def binary(%__MODULE__{xpacket: xpacket}), do: xpacket

  def write(%__MODULE__{} = data, io_device) do
    Logger.debug "Writing APP1.XMPExtension header"
    binary = binary(data)
    :ok = IO.binwrite(io_device, binary)
  end

  defimpl Exiffer.Serialize do
    def binary(xmp) do
      Exiffer.Header.APP1.XMPExtension.binary(xmp)
    end

    def puts(xmp) do
      Exiffer.Header.APP1.XMPExtension.puts(xmp)
    end

    def write(xmp, io_device) do
      Exiffer.Header.APP1.XMPExtension.write(xmp, io_device)
    end
  end
end
