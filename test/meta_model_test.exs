defmodule DAPCodegen.MetaModelTest do
  use ExUnit.Case

  defp build_meta_model() do
    File.read!(Path.join(:code.priv_dir(:dap_codegen), "debugAdapterProtocol.json"))
    |> Jason.decode!(keys: :atoms)
    |> DAPCodegen.MetaModel.new()
  end

  test "meta model is valid" do
    model = %DAPCodegen.MetaModel{} = build_meta_model()

    assert length(model.requests) > 0
    assert length(model.events) > 0
    assert length(model.structures) > 0
    assert length(model.enumerations) > 0
  end

  describe "requests" do
    test "all requests have common fields" do
      model = build_meta_model()

      for request = %DAPCodegen.Request{} <- model.requests do
        assert request.message_direction != nil
        assert request.command != nil
        assert is_binary(request.command)
        # assert request.result != nil
        assert request.documentation != nil
        assert request.arguments != nil

        if request.arguments != :none do
          assert request.arguments_required != nil
        end
      end
    end

    # request without arguments
    test "request without arguments" do
      model = build_meta_model()

      assert %DAPCodegen.Request{} =
               request = model.requests |> Enum.find(fn r -> r.command == "threads" end)

      assert request.arguments == :none
    end

    test "request with optional arguments" do
      model = build_meta_model()

      assert %DAPCodegen.Request{} =
               request =
               model.requests |> Enum.find(fn r -> r.command == "breakpointLocations" end)

      assert request.arguments == %DAPCodegen.ReferenceType{
               name: "BreakpointLocationsArguments"
             }

      assert request.arguments_required == false
    end

    test "request with required arguments" do
      model = build_meta_model()

      assert %DAPCodegen.Request{} =
               request = model.requests |> Enum.find(fn r -> r.command == "attach" end)

      assert request.arguments == %DAPCodegen.ReferenceType{
               name: "AttachRequestArguments"
             }

      assert request.arguments_required == true
    end

    test "client -> adapter requests" do
      model = build_meta_model()

      assert %DAPCodegen.Request{} =
               request = model.requests |> Enum.find(fn r -> r.command == "attach" end)

      assert request.message_direction == "client -> adapter"
    end

    test "adapter -> client requests" do
      model = build_meta_model()

      assert %DAPCodegen.Request{} =
               request = model.requests |> Enum.find(fn r -> r.command == "runInTerminal" end)

      assert request.message_direction == "adapter -> client"
    end
  end

  describe "events" do
    test "all events have common fields" do
      model = build_meta_model()

      for event = %DAPCodegen.Event{} <- model.events do
        assert event.event != nil
        assert is_binary(event.event)
        assert event.message_direction == "adapter -> client"
        assert event.documentation != nil
        assert event.body != nil

        if event.body != :none do
          assert event.body_required != nil
        end
      end
    end

    test "event with no body" do
      model = build_meta_model()

      assert %DAPCodegen.Event{} =
               event = model.events |> Enum.find(fn e -> e.event == "initialized" end)

      assert event.body_required == false
      # any type from base Event
      assert event.body == %DAPCodegen.OrType{
               items: [
                 %DAPCodegen.BaseType{name: :array},
                 %DAPCodegen.BaseType{name: :boolean},
                 %DAPCodegen.BaseType{name: :integer},
                 %DAPCodegen.BaseType{name: :null},
                 %DAPCodegen.BaseType{name: :number},
                 %DAPCodegen.BaseType{name: :object},
                 %DAPCodegen.BaseType{name: :string}
               ]
             }
    end

    test "event with optional body" do
      model = build_meta_model()

      assert %DAPCodegen.Event{} =
               event = model.events |> Enum.find(fn e -> e.event == "terminated" end)

      assert event.body_required == false
      assert %DAPCodegen.StructureLiteral{properties: body_properties} = event.body

      assert %DAPCodegen.Property{} =
               restart_property = body_properties |> Enum.find(&(&1.name == "restart"))

      assert restart_property.type == %DAPCodegen.OrType{
               items: [
                 %DAPCodegen.BaseType{name: :array},
                 %DAPCodegen.BaseType{name: :boolean},
                 %DAPCodegen.BaseType{name: :integer},
                 %DAPCodegen.BaseType{name: :null},
                 %DAPCodegen.BaseType{name: :number},
                 %DAPCodegen.BaseType{name: :object},
                 %DAPCodegen.BaseType{name: :string}
               ]
             }

      assert restart_property.optional == true
      assert restart_property.documentation != nil
    end

    test "event with required body" do
      model = build_meta_model()

      assert %DAPCodegen.Event{} =
               event = model.events |> Enum.find(fn e -> e.event == "continued" end)

      assert event.body_required == true
      assert %DAPCodegen.StructureLiteral{properties: body_properties} = event.body

      assert %DAPCodegen.Property{} =
               thread_id_property = body_properties |> Enum.find(&(&1.name == "threadId"))

      assert thread_id_property.type == %DAPCodegen.BaseType{name: :integer}
      assert thread_id_property.optional == false
      assert thread_id_property.documentation != nil

      assert %DAPCodegen.Property{} =
               all_threads_continued_property =
               body_properties |> Enum.find(&(&1.name == "allThreadsContinued"))

      assert all_threads_continued_property.type == %DAPCodegen.BaseType{name: :boolean}
      assert all_threads_continued_property.optional == true
      assert all_threads_continued_property.documentation != nil
    end
  end

  describe "structures" do
    test "all structures have common fields" do
      model = build_meta_model()

      for structure = %DAPCodegen.Structure{} <- model.structures do
        assert structure.name != nil
        assert is_binary(structure.name)
        assert structure.documentation != nil
        assert length(structure.properties) >= 0
        assert length(structure.extends) >= 0
      end
    end

    test "simple structure" do
      model = build_meta_model()

      assert %DAPCodegen.Structure{} =
               structure = model.structures |> Enum.find(fn s -> s.name == "ValueFormat" end)

      assert structure.extends == []

      assert %DAPCodegen.Property{} =
               hex_property = structure.properties |> Enum.find(fn p -> p.name == "hex" end)

      assert hex_property.type == %DAPCodegen.BaseType{name: :boolean}
      assert hex_property.optional == true
      assert hex_property.documentation != nil
    end

    test "simple structure with required fields" do
      model = build_meta_model()

      assert %DAPCodegen.Structure{} =
               structure = model.structures |> Enum.find(fn s -> s.name == "StepInArguments" end)

      assert structure.extends == []

      assert %DAPCodegen.Property{} =
               thread_id_property =
               structure.properties |> Enum.find(fn p -> p.name == "threadId" end)

      assert thread_id_property.type == %DAPCodegen.BaseType{name: :integer}
      assert thread_id_property.optional == false
      assert thread_id_property.documentation != nil
    end

    test "simple structure with ref fields" do
      model = build_meta_model()

      assert %DAPCodegen.Structure{} =
               structure = model.structures |> Enum.find(fn s -> s.name == "StepInArguments" end)

      assert structure.extends == []

      assert %DAPCodegen.Property{} =
               granularity_property =
               structure.properties |> Enum.find(fn p -> p.name == "granularity" end)

      assert granularity_property.type == %DAPCodegen.ReferenceType{
               name: "SteppingGranularity"
             }
    end

    test "allOf with no additional" do
      model = build_meta_model()

      assert %DAPCodegen.Structure{} =
               structure = model.structures |> Enum.find(fn s -> s.name == "NextResponse" end)

      assert structure.extends == [%DAPCodegen.ReferenceType{name: "Response"}]
      assert structure.properties == []
    end

    test "allOf with additional properties" do
      model = build_meta_model()

      assert %DAPCodegen.Structure{} =
               structure = model.structures |> Enum.find(fn s -> s.name == "StackFrameFormat" end)

      assert structure.extends == [
               %DAPCodegen.ReferenceType{name: "ValueFormat"}
             ]

      assert %DAPCodegen.Property{} =
               property =
               structure.properties |> Enum.find(fn p -> p.name == "parameterNames" end)

      assert property.type == %DAPCodegen.BaseType{name: :boolean}
      assert property.optional == true
      assert property.documentation != nil
    end

    test "allOf with overriding properties" do
      model = build_meta_model()

      assert %DAPCodegen.Structure{} =
               structure = model.structures |> Enum.find(fn s -> s.name == "ThreadsResponse" end)

      assert structure.extends == [%DAPCodegen.ReferenceType{name: "Response"}]

      assert %DAPCodegen.Property{} =
               body_property = structure.properties |> Enum.find(fn p -> p.name == "body" end)

      assert %DAPCodegen.Property{
               type: %DAPCodegen.StructureLiteral{
                 properties: [
                   %DAPCodegen.Property{
                     type: %DAPCodegen.ArrayType{
                       element: %DAPCodegen.ReferenceType{name: "Thread"}
                     },
                     optional: false,
                     name: "threads",
                     documentation: "All threads."
                   }
                 ]
               },
               optional: false,
               name: "body",
               documentation: nil
             } = body_property
    end

    test "oneOf" do
      model = build_meta_model()

      assert %DAPCodegen.Structure{name: "RestartArguments"} =
               structure = model.structures |> Enum.find(fn s -> s.name == "RestartArguments" end)

      assert %DAPCodegen.Property{} =
               one_of_property =
               structure.properties |> Enum.find(fn p -> p.name == "arguments" end)

      assert one_of_property.type == %DAPCodegen.OrType{
               items: [
                 %DAPCodegen.ReferenceType{name: "LaunchRequestArguments"},
                 %DAPCodegen.ReferenceType{name: "AttachRequestArguments"}
               ]
             }
    end
  end

  describe "enumerations" do
    test "all enumerations have common fields" do
      model = build_meta_model()

      for enumeration = %DAPCodegen.Enumeration{} <- model.enumerations do
        assert enumeration.name != nil
        assert enumeration.documentation != nil
        assert enumeration.type != nil
        assert length(enumeration.values) > 0
      end
    end

    test "enum without description" do
      model = build_meta_model()

      assert %DAPCodegen.Enumeration{} =
               enumeration =
               model.enumerations |> Enum.find(fn e -> e.name == "ExceptionBreakMode" end)

      assert enumeration.documentation != nil

      assert %DAPCodegen.EnumerationEntry{} =
               line_value = enumeration.values |> Enum.find(fn v -> v.name == "always" end)

      assert line_value.documentation == nil
    end

    test "enum with description" do
      model = build_meta_model()

      assert %DAPCodegen.Enumeration{} =
               enumeration =
               model.enumerations |> Enum.find(fn e -> e.name == "SteppingGranularity" end)

      assert enumeration.documentation != nil

      assert %DAPCodegen.EnumerationEntry{} =
               line_value = enumeration.values |> Enum.find(fn v -> v.name == "line" end)

      assert line_value.documentation != nil
    end

    # extensible enums
    test "extensible enum" do
      model = build_meta_model()

      assert %DAPCodegen.Enumeration{} =
               enumeration =
               model.enumerations
               |> Enum.find(fn e -> e.name == "BreakpointModeApplicability" end)

      assert enumeration.extensible == true
    end

    test "non-extensible enum" do
      model = build_meta_model()

      assert %DAPCodegen.Enumeration{} =
               enumeration =
               model.enumerations |> Enum.find(fn e -> e.name == "SteppingGranularity" end)

      assert enumeration.extensible == false
    end
  end
end
