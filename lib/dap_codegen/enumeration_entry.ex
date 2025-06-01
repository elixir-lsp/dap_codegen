defmodule DAPCodegen.EnumerationEntry do
  @moduledoc """
  Defines an enumeration entry.
  """

  use TypedStruct

  typedstruct do
    field :documentation, String.t()
    field :name, String.t(), enforce: true
    field :value, String.t() | integer(), enforce: true
  end

  def new(entry) do
    %__MODULE__{
      documentation: entry[:documentation],
      name: entry.name,
      value: entry.value
    }
  end

  defimpl DAPCodegen.Schematic do
    def to_string(entry, _metamodel) when is_integer(entry.value) do
      "#{entry.value}"
    end

    def to_string(entry, _metamodel) when is_binary(entry.value) do
      ~s|"#{entry.value}"|
    end
  end
end
