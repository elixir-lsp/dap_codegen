defmodule DAPCodegen.Event do
  @moduledoc """
  Represents a protocol event
  """

  alias DAPCodegen.Type
  alias DAPCodegen.PropertyName

  use TypedStruct

  typedstruct do
    field :documentation, String.t()
    field :message_direction, String.t(), enforce: true
    field :event, String.t(), enforce: true
    field :body, Type.t(), enforce: true
    field :body_required, boolean(), enforce: true
  end

  def new(event) do
    %__MODULE__{
      documentation: event[:documentation],
      message_direction: event[:message_direction],
      event: event[:event],
      body: Type.new(event[:body]),
      body_required: event[:body_required]
    }
  end

  defimpl DAPCodegen.Codegen do
    require EEx
    @path Path.join(:code.priv_dir(:dap_codegen), "event.ex.eex")

    def to_string(event, metamodel) do
      # Find the base Event and ProtocolMessage structures in the metamodel
      base_event = Enum.find(metamodel.structures, &(&1.raw_name == "Event"))
      protocol_message = Enum.find(metamodel.structures, &(&1.raw_name == "ProtocolMessage"))

      protocol_message_properties =
        protocol_message.properties |> Map.new(fn prop -> {prop.name, prop} end)

      event_properties = base_event.properties |> Map.new(fn prop -> {prop.name, prop} end)

      merge_properties = fn _k, v1 = %DAPCodegen.Property{}, v2 = %DAPCodegen.Property{} ->
        %{v2 | documentation: v2.documentation || v1.documentation}
      end

      merged_properties =
        protocol_message_properties
        |> Map.merge(event_properties, merge_properties)
        |> Map.values()
        |> Enum.sort_by(& &1.name)

      render(%{
        event: event,
        body: event.body,
        properties: merged_properties,
        metamodel: metamodel
      })
    end

    # Use shared property name formatting
    defp format_property_name(name), do: PropertyName.format(name)

    EEx.function_from_file(:defp, :render, @path, [:assigns])
  end

  defimpl DAPCodegen.Naming do
    def name(%{event: event}) do
      event
      |> String.replace("/", "_")
      |> String.replace("$", "Dollar")
      |> Macro.camelize()
      |> Kernel.<>("Event")
    end
  end
end
