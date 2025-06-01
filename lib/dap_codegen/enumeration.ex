defmodule DAPCodegen.Enumeration do
  @moduledoc """
  Defines an enumeration.
  """

  use TypedStruct

  alias DAPCodegen.{
    BaseType,
    EnumerationEntry
  }

  typedstruct do
    field :documentation, String.t()
    field :name, String.t(), enforce: true
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
      documentation: enumeration[:description],
      name: enumeration.name,
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
    require EEx
    @path Path.join(:code.priv_dir(:dap_codegen), "enumeration.ex.eex")

    def to_string(enumeration, metamodel) do
      render(%{
        enumeration: enumeration,
        values: enumeration.values,
        type:
          if(enumeration.type.name == :string,
            do: "String.t()",
            else: Enum.map_join(enumeration.values, " | ", &inspect(&1.value))
          ),
        metamodel: metamodel
      })
    end

    EEx.function_from_file(:defp, :render, @path, [:assigns])
  end

  defimpl DAPCodegen.Naming do
    def name(%{name: name}), do: name
  end
end
