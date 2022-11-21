defmodule Exiffer.JPEG do
  @moduledoc """
  Documentation for `Exiffer.JPEG`.
  """

  alias Exiffer.Binary
  alias Exiffer.Buffer
  alias Exiffer.Header.APP1
  alias Exiffer.Header.APP4
  alias Exiffer.Header.Data
  alias Exiffer.Header.JFIF
  alias Exiffer.Header.SOS
  require Logger

  @doc """
  Parse JPEG headers.
  """
  def headers(buffer, headers)

  def headers(%Buffer{data: <<0xff, 0xda, _rest::binary>>} = buffer, headers) do
    {sos, buffer} = SOS.new(buffer)
    {buffer, [sos | headers]}
  end

  def headers(
    %Buffer{
      data: <<
        0xff,
        0xe0,
        _length_binary::binary-size(2),
        "JFIF",
        version::binary-size(2),
        density_units,
        x_density::binary-size(2),
        y_density::binary-size(2),
        x_thumbnail,
        y_thumbnail,
        0x00,
        _rest::binary
      >>
    } = buffer,
    headers
  ) do
    Logger.debug ~s(Header "JFIF" at #{Integer.to_string(buffer.position, 16)})
    buffer = Buffer.skip(buffer, 18)
    thumbnail_bytes = 3 * x_thumbnail * y_thumbnail
    {thumbnail, buffer} = Buffer.consume(buffer, thumbnail_bytes)
    header = %JFIF{
      type: "JFIF APP0",
      version: version,
      density_units: density_units,
      x_density: Binary.to_integer(x_density),
      y_density: Binary.to_integer(y_density),
      x_thumbnail: x_thumbnail,
      y_thumbnail: y_thumbnail,
      thumbnail: thumbnail
    }
    headers(buffer, [header | headers])
  end

  def headers(%Buffer{data: <<0xff, 0xe1, _rest::binary>>} = buffer, headers) do
    Logger.debug ~s(Header "APP1" at #{Integer.to_string(buffer.position, 16)})
    {app1, buffer} = APP1.new(buffer)
    headers(buffer, [app1 | headers])
  end

  def headers(%Buffer{data: <<0xff, 0xe4, _rest::binary>>} = buffer, headers) do
    Logger.debug ~s(Header "APP4" at #{Integer.to_string(buffer.position, 16)})
    {app4, buffer} = APP4.new(buffer)
    headers(buffer, [app4 | headers])
  end

  def headers(%Buffer{data: <<0xff, 0xfe, length_bytes::binary-size(2), _rest::binary>>} = buffer, headers) do
    Logger.debug ~s(Header "COM" at #{Integer.to_string(buffer.position, 16)})
    buffer = Buffer.skip(buffer, 4)
    length = Binary.big_endian_to_integer(length_bytes)
    {comment, buffer} = Buffer.consume(buffer, length - 2)
    # TODO: only do this if length is odd
    buffer = Buffer.skip(buffer, 1)
    header = %Data{type: "JPEG COM Comment", data: comment}
    headers(buffer, [header | headers])
  end

  def headers(%Buffer{} = buffer, headers) do
    Logger.debug ~s(Header Data at #{Integer.to_string(buffer.position, 16)})
    {header, buffer} = Data.new(buffer)
    headers(buffer, [header | headers])
  end
end
