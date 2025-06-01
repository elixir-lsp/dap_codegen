defmodule DAPCodegen.ArrayType do
  @moduledoc """
  Represents an array type (e.g. `TextDocument[]`).
  """

  use TypedStruct

  alias DAPCodegen.Type

  typedstruct do
    field :element, Type.t(), enforce: true
  end

  def new(type) do
    %__MODULE__{
      element: Type.new(type.element)
    }
  end

  defimpl DAPCodegen.Codegen do
    def to_string(%{element: type}, metamodel) do
      "list(#{DAPCodegen.Codegen.to_string(type, metamodel)})"
    end
  end

  defimpl DAPCodegen.Schematic do
    def to_string(array_type, metamodel) do
      "list(#{DAPCodegen.Schematic.to_string(array_type.element, metamodel)})"
    end
  end
end
