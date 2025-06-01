defmodule DAPCodegen.Structure do
  @moduledoc """
  Defines the structure of an object literal.
  """

  alias DAPCodegen.{Type, Property, PropertyName}

  use TypedStruct

  typedstruct do
    field :documentation, String.t()
    field :extends, list(Type.t())
    field :name, String.t(), enforce: true
    field :raw_name, String.t(), enforce: true
    field :properties, list(Property.t()), enforce: true
  end

  def new(structure) do
    # if structure.name == "ThreadsResponse" do
    #   dbg(structure)
    # end
    {extends, properties, required_fields, documentation} =
      case structure do
        %{allOf: all_of} ->
          # Extract extends from $ref and properties from object type
          extends =
            all_of
            |> Enum.filter(&Map.has_key?(&1, :"$ref"))
            |> Enum.map(fn %{"$ref": ref} ->
              Type.new(%{"$ref": ref})
            end)

          # if structure.name == "ThreadsResponse" do
          #   # raise "NextResponse"
          #   dbg(extends)
          # end

          # Find the object type definition in allOf
          object_defs = Enum.filter(all_of, &(is_map(&1) and Map.get(&1, :type) == "object"))

          if length(object_defs) > 1 do
            raise "Multiple object definitions found in allOf: #{inspect(object_defs)}"
          end

          object_def = List.first(object_defs, %{})
          properties = Map.get(object_def, :properties, %{})
          required_fields = Map.get(object_def, :required, [])
          # Convert required fields to atoms
          required_fields = Enum.map(required_fields, &String.to_atom/1)

          #   if structure.name == "ThreadsResponse" do
          #     # raise "NextResponse"
          #     dbg(properties)
          #     for(
          #   {name, prop} <- properties,
          #   # Set optional to true if the field is not in the required list
          #   do:
          #     Property.new(
          #       Map.put(prop, :name, name)
          #       |> Map.put(:optional, name not in required_fields)
          #     )
          # )
          #   end

          {extends, properties, required_fields, object_def[:description]}

        %{type: "object"} ->
          required_fields = structure[:required] || []
          # Convert required fields to atoms
          required_fields = Enum.map(required_fields, &String.to_atom/1)

          {structure[:extends] || [], structure[:properties] || %{}, required_fields,
           structure[:description]}
      end

    %__MODULE__{
      documentation: documentation,
      extends: extends,
      name: transform_name(structure.name),
      raw_name: structure.name,
      properties:
        for(
          {name, prop} <- properties,
          # Set optional to true if the field is not in the required list
          do:
            Property.new(
              Map.put(prop, :name, name)
              |> Map.put(:optional, name not in required_fields)
            )
        )
    }
  end

  defp transform_name("_" <> name) do
    "Private" <> name
  end

  defp transform_name(name), do: name

  defimpl DAPCodegen.Codegen do
    require EEx
    @path Path.join(:code.priv_dir(:dap_codegen), "structure.ex.eex")

    def to_string(structure, metamodel) do
      render(%{
        structure: Map.from_struct(structure),
        properties: properties(structure, metamodel.structures),
        metamodel: metamodel
      })
    end

    defp properties(structure, structures) do
      extends = get_extended_properties(structure.extends, structures)

      # Create maps keyed by name for merging
      extended_props = Map.new(extends, fn prop -> {prop.name, prop} end)
      current_props = Map.new(structure.properties, fn prop -> {prop.name, prop} end)

      # Merge with preference to current properties, but keep documentation from extends if none exists
      merge_properties = fn _k, v1 = %DAPCodegen.Property{}, v2 = %DAPCodegen.Property{} ->
        %{v2 | documentation: v2.documentation || v1.documentation}
      end

      Map.merge(extended_props, current_props, merge_properties)
      |> Map.values()
      |> Enum.sort_by(& &1.name)
    end

    defp get_extended_properties(extends, structures) do
      Enum.flat_map(extends, fn e ->
        extended_struct = Enum.find(structures, &(&1.raw_name == e.name))
        extended_props = get_extended_properties(extended_struct.extends, structures)
        extended_struct.properties ++ extended_props
      end)
    end

    # If optional is true, don't enforce the field
    defp enforce(true), do: ""
    # If optional is false or nil, enforce the field
    defp enforce(value) when value in [false, nil], do: ", enforce: true"

    defp maybe_wrap_in_optional(true, key), do: "optional(#{key})"
    defp maybe_wrap_in_optional(_, key), do: key

    defp maybe_replace_with_recurse(text, type) do
      String.replace(text, type, "{__MODULE__, :schematic, []}")
    end

    # Use shared property name formatting
    defp format_property_name(name), do: PropertyName.format(name)

    EEx.function_from_file(:defp, :render, @path, [:assigns])
  end

  defimpl DAPCodegen.Naming do
    def name(%{name: name}), do: name
  end
end
