defmodule DAPCodegen.PropertyName do
  @moduledoc """
  Shared utilities for property name formatting.
  """

  @doc """
  Formats a property name into a valid Elixir identifier.
  """
  def format(name) when is_binary(name) do
    name
    |> String.split(~r/(?=[A-Z])/)
    |> Enum.map(&String.downcase/1)
    |> Enum.join("_")
  end

  def format(name) do
    raise "Unexpected property name type: #{inspect(name)}"
  end
end
