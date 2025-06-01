defmodule DAPCodegen.MapType do
  @moduledoc """
  Represents a JSON object map (e.g. `interface Map<K extends string | integer, V> { [key: K] => V; }`).
  """

  alias DAPCodegen.BaseType
  alias DAPCodegen.Type

  use TypedStruct

  typedstruct do
    field :key, Type.t(), enforce: true
    field :value, Type.t(), enforce: true
    field :documentation, String.t()
  end

  def new(type) do
    %__MODULE__{
      key: BaseType.new(%{name: "string"}),
      value: Type.new(type.value),
      documentation: type[:documentation]
    }
  end

  defimpl DAPCodegen.Schematic do
    def to_string(type, metamodel) do
      "map(keys: #{DAPCodegen.Schematic.to_string(type.key, metamodel)}, values: #{DAPCodegen.Schematic.to_string(type.value, metamodel)})"
    end
  end

  defimpl DAPCodegen.Codegen do
    def to_string(map_type, metamodel) do
      "%{optional(#{DAPCodegen.Codegen.to_string(map_type.key, metamodel)}) => #{DAPCodegen.Codegen.to_string(map_type.value, metamodel)}}"
    end
  end
end
