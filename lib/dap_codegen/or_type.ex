defmodule DAPCodegen.OrType do
  @moduledoc """
  Represents a union type in the protocol.
  """

  use TypedStruct

  alias DAPCodegen.Type

  typedstruct do
    field :items, list(Type.t()), enforce: true
  end

  def new(%{items: items} = _type) do
    %__MODULE__{
      items: items
    }
  end

  defimpl DAPCodegen.Codegen do
    def to_string(%{items: items}, metamodel) do
      items
      |> Enum.map(&DAPCodegen.Codegen.to_string(&1, metamodel))
      |> Enum.join(" | ")
    end
  end

  defimpl DAPCodegen.Schematic do
    def to_string(%{items: items}, metamodel) do
      items_str =
        items
        |> Enum.map(&DAPCodegen.Schematic.to_string(&1, metamodel))
        |> Enum.join(", ")

      "oneof([#{items_str}])"
    end
  end
end
