defmodule DAPCodegen.Property do
  @moduledoc """
  Represents an object property.
  """

  alias DAPCodegen.Type

  use TypedStruct

  typedstruct do
    field :documentation, String.t()
    field :name, String.t(), enforce: true
    field :optional, boolean(), enforce: true
    field :type, Type.t(), enforce: true
  end

  def new(type) do
    # Extract the type definition from the property
    property_type =
      cond do
        Map.has_key?(type, :"$ref") -> %{:"$ref" => type[:"$ref"]}
        Map.has_key?(type, :oneOf) -> type[:oneOf]
        true -> type
      end

    %__MODULE__{
      documentation: type[:description],
      name: to_string(type.name),
      optional: type[:optional],
      type: Type.new(property_type)
    }
  end
end
