defmodule DAPCodegen.Type do
  @moduledoc """
  Represents a type in the protocol.
  """

  use TypedStruct

  alias DAPCodegen.{
    BaseType,
    ReferenceType,
    ArrayType,
    MapType,
    OrType,
    StructureLiteral,
    EnumerationLiteral
  }

  @type t() ::
          BaseType.t()
          | ReferenceType.t()
          | ArrayType.t()
          | MapType.t()
          | OrType.t()
          | StructureLiteral.t()
          | EnumerationLiteral.t()
          | :none

  # Handle :none atom
  def new(:none), do: :none

  # Handle list of type names directly
  def new(types) when is_list(types) do
    OrType.new(%{
      items: Enum.map(types, &new/1),
      kind: :or
    })
  end

  # Handle string type names directly
  def new(type) when is_binary(type) do
    BaseType.new(%{name: type})
  end

  def new(%{type: type_name} = type) when is_binary(type_name) do
    case type_name do
      "array" ->
        element = Map.get(type, :items)

        if element do
          ArrayType.new(%{
            element: element,
            kind: :array
          })
        else
          # If items is not specified, use base type
          BaseType.new(%{name: type_name})
        end

      "object"
      when is_map_key(type, :additionalProperties) and type.additionalProperties != false ->
        case type.additionalProperties do
          true ->
            MapType.new(%{
              value: "any",
              kind: :map
            })

          %{type: type} = properties ->
            MapType.new(%{
              value: type,
              kind: :map,
              documentation: properties[:description]
            })
        end

      "object" when is_map(type.properties) ->
        required = Map.get(type, :required, []) |> Enum.map(&String.to_atom/1)

        StructureLiteral.new(%{
          properties:
            Enum.map(type.properties, fn {name, prop} ->
              prop
              |> Map.put(:name, name)
              |> Map.put(:optional, name not in required)
            end)
        })

      "string" when is_map_key(type, :enum) or is_map_key(type, :_enum) ->
        EnumerationLiteral.new(type)

      primitive when primitive in ["string", "integer", "boolean", "number"] ->
        BaseType.new(%{name: primitive})

      _ ->
        BaseType.new(%{name: type_name})
    end
  end

  # Handle DAP reference format
  def new(%{"$ref": ref}) do
    ReferenceType.new(%{
      name: String.replace(ref, "#/definitions/", ""),
      kind: :reference
    })
  end

  # Handle DAP union types (multiple allowed types)
  def new(%{type: types}) when is_list(types) do
    OrType.new(%{
      items: Enum.map(types, &new(%{type: &1})),
      kind: :or
    })
  end

  # Handle DAP additional properties
  def new(%{additionalProperties: true}) do
    MapType.new(%{
      key: BaseType.new(%{name: "string"}),
      value: BaseType.new(%{name: "any"}),
      kind: :map
    })
  end
end
