defmodule DAPCodegen.Request do
  @moduledoc """
  Represents a protocol request
  """

  alias DAPCodegen.Type
  alias DAPCodegen.PropertyName
  use TypedStruct

  typedstruct do
    field :documentation, String.t()
    field :response_documentation, String.t()
    field :message_direction, String.t(), enforce: true
    field :response_direction, String.t(), enforce: true
    field :command, String.t(), enforce: true
    field :arguments, Type.t(), enforce: true
    field :arguments_required, boolean(), enforce: true
    field :body, Type.t(), enforce: true
    field :body_required, boolean(), enforce: true
  end

  def new(request) do
    %__MODULE__{
      documentation: request[:documentation],
      response_documentation:
        request[:response_documentation] || "A response to the #{request[:command]} request",
      message_direction: request[:message_direction],
      response_direction: request[:response_direction],
      command: request[:command],
      arguments: Type.new(request[:arguments]),
      arguments_required: request[:arguments_required],
      body: Type.new(request[:body]),
      body_required: request[:body_required]
    }
  end

  defimpl DAPCodegen.Codegen do
    require EEx
    @path Path.join(:code.priv_dir(:dap_codegen), "request.ex.eex")

    def to_string(request, metamodel) do
      # Find the base Request and ProtocolMessage structures in the metamodel
      base_request = Enum.find(metamodel.structures, &(&1.raw_name == "Request"))
      base_response = Enum.find(metamodel.structures, &(&1.raw_name == "Response"))
      protocol_message = Enum.find(metamodel.structures, &(&1.raw_name == "ProtocolMessage"))

      protocol_message_properties =
        protocol_message.properties |> Map.new(fn prop -> {prop.name, prop} end)

      request_properties = base_request.properties |> Map.new(fn prop -> {prop.name, prop} end)
      response_properties = base_response.properties |> Map.new(fn prop -> {prop.name, prop} end)

      merge_properties = fn _k, v1 = %DAPCodegen.Property{}, v2 = %DAPCodegen.Property{} ->
        %{v2 | documentation: v2.documentation || v1.documentation}
      end

      merged_properties =
        protocol_message_properties
        |> Map.merge(request_properties, merge_properties)
        |> Map.values()
        |> Enum.sort_by(& &1.name)

      merged_response_properties =
        protocol_message_properties
        |> Map.merge(response_properties, merge_properties)
        |> Map.values()
        |> Enum.sort_by(& &1.name)

      render(%{
        request: request,
        arguments: request.arguments,
        body: request.body,
        metamodel: metamodel,
        properties: merged_properties,
        response_properties: merged_response_properties
      })
    end

    # Use shared property name formatting
    defp format_property_name(name), do: PropertyName.format(name)

    EEx.function_from_file(:defp, :render, @path, [:assigns])
  end

  defimpl DAPCodegen.Naming do
    def name(%{command: command}) do
      command
      |> String.replace("/", "_")
      |> String.replace("$", "Dollar")
      |> Macro.camelize()
    end
  end
end
