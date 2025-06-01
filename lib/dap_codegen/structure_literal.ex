defmodule DAPCodegen.StructureLiteral do
  @moduledoc """
  Represents a structure literal type in the protocol.
  """

  use TypedStruct

  alias DAPCodegen.{
    Property,
    PropertyName
  }

  typedstruct do
    field :properties, list(Property.t()), enforce: true
  end

  def new(%{properties: properties}) do
    %__MODULE__{
      properties: Enum.map(properties, &Property.new/1)
    }
  end

  defimpl DAPCodegen.Codegen do
    def to_string(%{properties: properties}, metamodel) do
      props =
        properties
        |> Enum.map_join(", ", fn prop ->
          if prop.optional do
            "optional(:#{PropertyName.format(prop.name)}) => #{DAPCodegen.Codegen.to_string(prop.type, metamodel)}"
          else
            "required(:#{PropertyName.format(prop.name)}) => #{DAPCodegen.Codegen.to_string(prop.type, metamodel)}"
          end
        end)

      "%{#{props}}"
    end
  end

  defimpl DAPCodegen.Schematic do
    def to_string(%{properties: properties}, metamodel) do
      # Generate the property definitions
      props =
        properties
        |> Enum.map_join(",\n        ", fn prop ->
          key = inspect({to_string(prop.name), String.to_atom(PropertyName.format(prop.name))})
          type = DAPCodegen.Schematic.to_string(prop.type, metamodel)

          if prop.optional do
            "optional(#{key}) => #{type}"
          else
            "#{key} => #{type}"
          end
        end)

      "map(%{\n        #{props}\n      })"
    end
  end
end
