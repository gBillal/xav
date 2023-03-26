defmodule Xav.Reader do
  @moduledoc """
  Media reader.
  """

  @type t() :: %__MODULE__{
          reader: reference(),
          in_format: atom(),
          out_format: atom(),
          sample_rate: integer() | nil,
          bit_rate: integer(),
          duration: integer(),
          codec: atom()
        }

  @enforce_keys [:reader, :in_format, :out_format, :bit_rate, :duration, :codec]
  defstruct @enforce_keys ++ [:sample_rate]

  @doc """
  The same as new/1 but raises on error.
  """
  @spec new!(String.t(), boolean(), boolean()) :: t()
  def new!(path, video? \\ true, device? \\ false) do
    case new(path, video?, device?) do
      {:ok, reader} -> reader
      {:error, reason} -> raise "Couldn't create a new reader. Reason: #{inspect(reason)}"
    end
  end

  @doc """
  Creates a new media reader.
  """
  @spec new(String.t(), boolean(), boolean()) :: {:ok, t()} | {:error, term()}
  def new(path, video? \\ true, device? \\ false) do
    case Xav.NIF.new_reader(path, to_int(device?), to_int(video?)) do
      {:ok, reader, in_format, out_format, sample_rate, bit_rate, duration, codec} ->
        {:ok,
         %__MODULE__{
           reader: reader,
           in_format: in_format,
           out_format: out_format,
           sample_rate: sample_rate,
           bit_rate: bit_rate,
           duration: duration,
           codec: to_human_readable(codec)
         }}

      {:ok, reader, in_format, out_format, bit_rate, duration, codec} ->
        {:ok,
         %__MODULE__{
           reader: reader,
           in_format: in_format,
           out_format: out_format,
           bit_rate: bit_rate,
           duration: duration,
           codec: to_human_readable(codec)
         }}

      {:error, _reason} = err ->
        err
    end
  end

  @doc """
  Reads next frame.

  Frame is always decoded.
  """
  @spec next_frame(t()) :: {:ok, Xav.Frame.t()} | {:error, :eof}
  def next_frame(%__MODULE__{reader: reader}) do
    case Xav.NIF.next_frame(reader) do
      {:ok, {data, format, width, height, pts}} ->
        {:ok, Xav.Frame.new(data, format, width, height, pts)}

      {:ok, {data, format, samples, pts}} ->
        {:ok, Xav.Frame.new(data, format, samples, pts)}

      {:error, :eof} = err ->
        err
    end
  end

  defp to_human_readable(:libdav1d), do: :av1
  defp to_human_readable(:mp3float), do: :mp3
  defp to_human_readable(other), do: other

  defp to_int(true), do: 1
  defp to_int(false), do: 0
end
