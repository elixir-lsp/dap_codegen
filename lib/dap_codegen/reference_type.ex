defmodule DAPCodegen.ReferenceType do
  @moduledoc """
  Represents a reference to another type
  """

  use TypedStruct

  typedstruct do
    field :name, String.t(), enforce: true
  end

  def new(type) do
    %__MODULE__{
      name: type.name
    }
  end

  defimpl DAPCodegen.Codegen do
    def to_string(%{name: name}, metamodel) do
      cond do
        Enum.any?(metamodel.structures, &(&1.name == name)) ->
          "GenDAP.Structures.#{name}.t()"

        Enum.any?(metamodel.enumerations, &(&1.name == name)) ->
          "GenDAP.Enumerations.#{name}.t()"

        true ->
          raise "Unknown reference type: #{name}"
      end
    end
  end

  defimpl DAPCodegen.Schematic do
    def to_string(%{name: name}, metamodel) do
      cond do
        Enum.any?(metamodel.structures, &(&1.name == name)) ->
          "GenDAP.Structures.#{name}.schematic()"

        Enum.any?(metamodel.enumerations, &(&1.name == name)) ->
          "GenDAP.Enumerations.#{name}.schematic()"

        true ->
          raise "Unknown reference type: #{name}"
      end
    end
  end
end
