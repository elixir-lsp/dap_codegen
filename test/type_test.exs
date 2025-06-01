defmodule DAPCodegen.TypeTest do
  use ExUnit.Case

  # :none
  test "none" do
    assert DAPCodegen.Type.new(:none) == :none
  end

  # base types from https://json-schema.org/draft-04/schema#
  test "base types" do
    assert DAPCodegen.Type.new("array") == %DAPCodegen.BaseType{name: :array}
    assert DAPCodegen.Type.new("boolean") == %DAPCodegen.BaseType{name: :boolean}
    assert DAPCodegen.Type.new("integer") == %DAPCodegen.BaseType{name: :integer}
    assert DAPCodegen.Type.new("null") == %DAPCodegen.BaseType{name: :null}
    assert DAPCodegen.Type.new("number") == %DAPCodegen.BaseType{name: :number}
    assert DAPCodegen.Type.new("object") == %DAPCodegen.BaseType{name: :object}
    assert DAPCodegen.Type.new("string") == %DAPCodegen.BaseType{name: :string}
  end

  test "list of types" do
    assert DAPCodegen.Type.new(["string", "integer"]) == %DAPCodegen.OrType{
             items: [%DAPCodegen.BaseType{name: :string}, %DAPCodegen.BaseType{name: :integer}]
           }
  end

  # reference
  test "reference" do
    assert DAPCodegen.Type.new(%{"$ref": "#/definitions/Foo"}) == %DAPCodegen.ReferenceType{
             name: "Foo"
           }
  end

  # object with no properties
  test "object with no properties" do
    assert DAPCodegen.Type.new(%{type: "object"}) == %DAPCodegen.BaseType{name: :object}
  end

  # object with properties
  test "object with properties" do
    assert DAPCodegen.Type.new(%{
             type: "object",
             properties: %{
               foo: %{type: "string"},
               bar: %{type: "integer", description: "bar description"}
             }
           }) ==
             %DAPCodegen.StructureLiteral{
               properties: [
                 %DAPCodegen.Property{
                   name: "foo",
                   type: %DAPCodegen.BaseType{name: :string},
                   optional: true
                 },
                 %DAPCodegen.Property{
                   name: "bar",
                   type: %DAPCodegen.BaseType{name: :integer},
                   documentation: "bar description",
                   optional: true
                 }
               ]
             }
  end

  test "object with required properties" do
    assert DAPCodegen.Type.new(%{
             type: "object",
             required: ["foo"],
             properties: %{
               foo: %{type: "string"},
               bar: %{type: "integer", description: "bar description"}
             }
           }) ==
             %DAPCodegen.StructureLiteral{
               properties: [
                 %DAPCodegen.Property{
                   name: "foo",
                   type: %DAPCodegen.BaseType{name: :string},
                   optional: false
                 },
                 %DAPCodegen.Property{
                   name: "bar",
                   type: %DAPCodegen.BaseType{name: :integer},
                   documentation: "bar description",
                   optional: true
                 }
               ]
             }
  end

  # object with additional properties
  test "object with additional properties" do
    assert DAPCodegen.Type.new(%{type: "object", additionalProperties: true}) ==
             %DAPCodegen.MapType{
               key: %DAPCodegen.BaseType{name: :string},
               value: %DAPCodegen.BaseType{name: :any}
             }

    assert DAPCodegen.Type.new(%{
             type: "object",
             additionalProperties: %{
               type: ["null", "string"],
               description: "additional properties description"
             }
           }) ==
             %DAPCodegen.MapType{
               documentation: "additional properties description",
               key: %DAPCodegen.BaseType{name: :string},
               value: %DAPCodegen.OrType{
                 items: [%DAPCodegen.BaseType{name: :null}, %DAPCodegen.BaseType{name: :string}]
               }
             }
  end

  # object with oneOf
  test "object with oneOf" do
    assert %DAPCodegen.StructureLiteral{
             properties: [property]
           } =
             DAPCodegen.Type.new(%{
               type: "object",
               properties: %{
                 foo: %{oneOf: [%{"$ref": "#/definitions/Foo"}, %{"$ref": "#/definitions/Bar"}]}
               }
             })

    assert property.type == %DAPCodegen.OrType{
             items: [
               %DAPCodegen.ReferenceType{name: "Foo"},
               %DAPCodegen.ReferenceType{name: "Bar"}
             ]
           }
  end

  # array with no items
  test "array with no items" do
    assert DAPCodegen.Type.new(%{type: "array"}) == %DAPCodegen.BaseType{name: :array}
  end

  # array with items
  test "array with items" do
    assert DAPCodegen.Type.new(%{type: "array", items: %{type: "string"}}) ==
             %DAPCodegen.ArrayType{element: %DAPCodegen.BaseType{name: :string}}

    assert DAPCodegen.Type.new(%{type: "array", items: %{"$ref": "#/definitions/Foo"}}) ==
             %DAPCodegen.ArrayType{
               element: %DAPCodegen.ReferenceType{name: "Foo"}
             }
  end

  # enum
  test "enum" do
    assert DAPCodegen.Type.new(%{type: "string", enum: ["foo", "bar"]}) ==
             %DAPCodegen.EnumerationLiteral{
               type: %DAPCodegen.BaseType{name: :string},
               extensible: false,
               values: [
                 %DAPCodegen.EnumerationEntry{value: "foo", name: "foo", documentation: nil},
                 %DAPCodegen.EnumerationEntry{value: "bar", name: "bar", documentation: nil}
               ]
             }

    assert DAPCodegen.Type.new(%{type: "string", _enum: ["foo", "bar"]}) ==
             %DAPCodegen.EnumerationLiteral{
               type: %DAPCodegen.BaseType{name: :string},
               extensible: true,
               values: [
                 %DAPCodegen.EnumerationEntry{value: "foo", name: "foo", documentation: nil},
                 %DAPCodegen.EnumerationEntry{value: "bar", name: "bar", documentation: nil}
               ]
             }
  end

  # enum with descriptions
  test "enum with descriptions" do
    assert DAPCodegen.Type.new(%{
             type: "string",
             enum: ["foo", "bar"],
             enumDescriptions: ["foo description", "bar description"]
           }) == %DAPCodegen.EnumerationLiteral{
             type: %DAPCodegen.BaseType{name: :string},
             extensible: false,
             values: [
               %DAPCodegen.EnumerationEntry{
                 value: "foo",
                 name: "foo",
                 documentation: "foo description"
               },
               %DAPCodegen.EnumerationEntry{
                 value: "bar",
                 name: "bar",
                 documentation: "bar description"
               }
             ]
           }

    assert DAPCodegen.Type.new(%{
             type: "string",
             _enum: ["foo", "bar"],
             enumDescriptions: ["foo description", "bar description"]
           }) == %DAPCodegen.EnumerationLiteral{
             type: %DAPCodegen.BaseType{name: :string},
             extensible: true,
             values: [
               %DAPCodegen.EnumerationEntry{
                 value: "foo",
                 name: "foo",
                 documentation: "foo description"
               },
               %DAPCodegen.EnumerationEntry{
                 value: "bar",
                 name: "bar",
                 documentation: "bar description"
               }
             ]
           }
  end
end
