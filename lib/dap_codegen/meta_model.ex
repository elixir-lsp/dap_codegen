defmodule DAPCodegen.MetaModel do
  @moduledoc """
  The actual meta model.
  """

  alias DAPCodegen.{
    Enumeration,
    Event,
    Request,
    Structure
  }

  use TypedStruct

  typedstruct enforce: true do
    field :enumerations, list(Enumeration.t()), default: []
    field :events, list(Event.t()), default: []
    field :requests, list(Request.t()), default: []
    field :structures, list(Structure.t()), default: []
  end

  def new(%{definitions: definitions}) when is_map(definitions) do
    # Handle DAP schema format

    structures =
      definitions
      |> Enum.map(fn {name, def} -> Map.put(def, :name, to_string(name)) end)
      |> Enum.filter(&is_valid_structure?/1)

    # Extract requests, events and other structures
    {requests, events, other_structures} =
      Enum.reduce(structures, {[], [], []}, fn struct, {reqs, events, others} ->
        name = to_string(struct.name)

        cond do
          String.ends_with?(name, "Request") and name != "Request" ->
            {[to_request(struct, definitions) | reqs], events, others}

          String.ends_with?(name, "Event") and name != "Event" ->
            {reqs, [to_event(struct, definitions) | events], others}

          true ->
            {reqs, events, [struct | others]}
        end
      end)

    # Extract enums
    enums =
      definitions
      |> Enum.filter(fn {_name, def} ->
        is_map(def) and (Map.has_key?(def, :_enum) or Map.has_key?(def, :enum))
      end)
      |> Enum.map(fn {name, def} ->
        Map.merge(def, %{
          name: to_string(name),
          type: to_string(def[:type])
        })
      end)

    %__MODULE__{
      enumerations: Enum.map(enums, &Enumeration.new/1),
      events: Enum.map(events, &Event.new/1),
      requests: Enum.map(requests, &Request.new/1),
      structures: Enum.map(other_structures, &Structure.new/1)
    }
  end

  # Handle DAP schema format
  def new(%{enumerations: e, events: n, requests: r, structures: s}) do
    %__MODULE__{
      enumerations: for(enum <- e || [], do: Enumeration.new(enum)),
      events: for(event <- n || [], do: Event.new(event)),
      requests: for(req <- r || [], do: Request.new(req)),
      structures: for(struct <- s || [], do: Structure.new(struct))
    }
  end

  # Check if a definition is a valid structure (either direct or through allOf)
  defp is_valid_structure?(def) do
    cond do
      is_map(def) and Map.has_key?(def, :type) and def.type == "object" ->
        true

      is_map(def) and Map.has_key?(def, :allOf) ->
        # Check if any of the allOf entries is an object type
        Enum.any?(def.allOf, fn
          %{type: "object"} -> true
          _ -> false
        end)

      true ->
        false
    end
  end

  # Extract properties from allOf structure
  defp extract_properties(definition) do
    case definition do
      %{allOf: all_of} when is_list(all_of) ->
        # Find the object type definition in allOf
        Enum.find(all_of, fn
          %{type: "object", properties: _} -> true
          _ -> false
        end)

      _ ->
        definition
    end
  end

  @reverse_requests [
    "runInTerminal",
    "startDebugging"
  ]

  # Convert DAP Request definition to our format
  defp to_request(request_def, definitions) do
    # Extract command from properties
    properties = extract_properties(request_def)

    command =
      case properties do
        %{properties: %{command: %{enum: [command | _]}}} -> command
        _ -> request_def.name
      end

    # Find corresponding response
    response_name = String.replace(request_def.name, "Request", "Response")
    response_def = definitions[String.to_atom(response_name)]

    response_properties = extract_properties(response_def)

    # Extract response body type if present
    body =
      case response_properties do
        %{properties: %{body: body}} when not is_nil(body) -> body
        _ -> :none
      end

    # Extract arguments from properties if they exist
    arguments =
      case properties do
        %{properties: %{arguments: arguments}} when not is_nil(arguments) -> arguments
        _ -> :none
      end

    # Check if request arguments are required
    required_fields = properties[:required] || []
    arguments_required = "arguments" in required_fields

    # Check if response body is required
    response_required_fields = response_properties[:required] || []
    body_required = "body" in response_required_fields

    base = %{
      documentation: properties[:description],
      response_documentation: response_properties[:description],
      command: command,
      body: body,
      message_direction:
        if(command in @reverse_requests, do: "adapter -> client", else: "client -> adapter"),
      response_direction:
        if(command in @reverse_requests, do: "client -> adapter", else: "adapter -> client")
    }

    base =
      if arguments do
        Map.merge(base, %{
          arguments: arguments,
          arguments_required: arguments_required
        })
      else
        base
      end

    if body do
      Map.merge(base, %{
        body: body,
        body_required: body_required
      })
    else
      base
    end
  end

  # Convert DAP Event definition to our format
  defp to_event(event_def, definitions) do
    properties = extract_properties(event_def)

    # Extract event name from properties
    event_name =
      case properties do
        %{properties: %{event: %{enum: [event | _]}}} -> event
        _ -> String.replace(event_def.name, "Event", "")
      end

    # Get the base Event definition
    event_base = definitions[:Event]
    event_base_props = extract_properties(event_base)

    # Extract body type from the specific event if it has one, otherwise use the base Event body type
    {body, body_required} =
      case properties do
        %{properties: %{body: body}} ->
          # Check if body is required
          required_fields = properties[:required] || []
          body_required = "body" in required_fields

          # This event has a specific body type
          {body, body_required}

        _ ->
          # Use the base Event body type
          case event_base_props do
            %{properties: %{body: body}} ->
              required_fields = (event_base_props[:required] || []) |> Enum.map(&to_string/1)
              body_required = "body" in required_fields
              {body, body_required}

            _ ->
              nil
          end
      end

    %{
      documentation: properties[:description],
      event: event_name,
      body: body,
      body_required: body_required,
      message_direction: "adapter -> client"
    }
  end
end
