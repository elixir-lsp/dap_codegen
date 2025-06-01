defmodule DAPCodegen.BaseType do
  @moduledoc """
  Represents a base type in the protocol.
  includes all types defined in https://json-schema.org/draft-04/schema# plus `any`
  """

  use TypedStruct

  typedstruct do
    field :name, atom(), enforce: true
  end

  def new(%{name: name}) do
    %__MODULE__{
      name: to_type_atom(name)
    }
  end

  defp to_type_atom(name) when is_binary(name) do
    case name do
      "string" -> :string
      "integer" -> :integer
      "boolean" -> :boolean
      "null" -> :null
      "array" -> :array
      "object" -> :object
      "number" -> :number
      "any" -> :any
    end
  end

  defimpl DAPCodegen.Codegen do
    def to_string(%{name: :string}, _), do: "String.t()"
    def to_string(%{name: :integer}, _), do: "integer()"
    def to_string(%{name: :boolean}, _), do: "boolean()"
    def to_string(%{name: :null}, _), do: "nil"
    def to_string(%{name: :array}, _), do: "list()"
    def to_string(%{name: :object}, _), do: "map()"
    def to_string(%{name: :number}, _), do: "number()"
    def to_string(%{name: :any}, _), do: "any()"
  end

  defimpl DAPCodegen.Schematic do
    def to_string(%{name: :string}, _), do: "str()"
    def to_string(%{name: :integer}, _), do: "int()"
    def to_string(%{name: :boolean}, _), do: "bool()"
    def to_string(%{name: :null}, _), do: "nil"
    def to_string(%{name: :array}, _), do: "list()"
    def to_string(%{name: :object}, _), do: "map()"
    def to_string(%{name: :number}, _), do: "oneof([int(), float()])"
    def to_string(%{name: :any}, _), do: "any()"
  end
end
