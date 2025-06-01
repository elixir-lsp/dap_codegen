defmodule DAPCodegen.EnumerationLiteral do
  @moduledoc """
  Defines an enumeration literal.
  """

  use TypedStruct

  alias DAPCodegen.{
    BaseType,
    EnumerationEntry
  }

  typedstruct do
    field :type, BaseType.t(), enforce: true
    field :values, list(EnumerationEntry.t()), default: [], enforce: true
    field :extensible, boolean(), default: false
  end

  def new(enumeration) do
    values = enumeration[:enum] || enumeration[:_enum]

    values =
      values
      |> Enum.map(
        &%{
          name: &1,
          value: &1,
          documentation: get_enum_description(enumeration, values, &1)
        }
      )

    %__MODULE__{
      type: BaseType.new(%{name: enumeration[:type] || "string"}),
      values: for(e <- values, do: EnumerationEntry.new(e)),
      extensible: Map.has_key?(enumeration, :_enum)
    }
  end

  # Helper to get enum value description from enumDescriptions if available
  defp get_enum_description(enumeration, values, value) do
    case enumeration do
      %{enumDescriptions: descriptions} ->
        case Enum.find_index(values, &(&1 == value)) do
          nil -> nil
          index -> Enum.at(descriptions, index)
        end

      _ ->
        nil
    end
  end

  defimpl DAPCodegen.Codegen do
    def to_string(%{values: values, extensible: extensible, type: type}, metamodel) do
      if type.name == :string do
        "String.t()"
      else
        if extensible do
          Enum.map_join(values, " | ", &inspect(&1.value)) <>
            " | " <> DAPCodegen.Codegen.to_string(type, metamodel)
        else
          Enum.map_join(values, " | ", &inspect(&1.value))
        end
      end
    end
  end

  defimpl DAPCodegen.Schematic do
    def to_string(%{values: values, extensible: extensible, type: type}, metamodel) do
      values_str =
        values
        |> Enum.map(&DAPCodegen.Schematic.to_string(&1, metamodel))
        |> Enum.join(", ")

      values_str =
        if extensible do
          values_str <> ", " <> DAPCodegen.Schematic.to_string(type, metamodel)
        else
          values_str
        end

      "oneof([#{values_str}])"
    end
  end
end
