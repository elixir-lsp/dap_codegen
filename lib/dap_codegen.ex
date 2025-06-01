defmodule DAPCodegen do
  require EEx

  alias DAPCodegen.{
    Enumeration,
    Event,
    Request,
    Structure
  }

  def generate(argv) when is_list(argv) do
    {opts, _} = OptionParser.parse!(argv, strict: [path: :string])
    path = opts[:path]

    File.rm_rf!(path)

    %DAPCodegen.MetaModel{} =
      metamodel =
      File.read!(Path.join(:code.priv_dir(:dap_codegen), "debugAdapterProtocol.json"))
      |> Jason.decode!(keys: :atoms)
      |> DAPCodegen.MetaModel.new()

    for mod <-
          metamodel.structures ++
            metamodel.requests ++
            metamodel.events ++ metamodel.enumerations,
        DAPCodegen.Naming.name(mod) not in ["Request", "Response", "Event", "ProtocolMessage"],
        DAPCodegen.Naming.name(mod) == "ErrorResponse" or
          not String.ends_with?(DAPCodegen.Naming.name(mod), "Response") do
      source_code = DAPCodegen.Codegen.to_string(mod, metamodel)

      path =
        case mod do
          %Enumeration{} -> Path.join(path, "enumerations")
          %Event{} -> Path.join(path, "events")
          %Request{} -> Path.join(path, "requests")
          %Structure{} -> Path.join(path, "structures")
        end

      File.mkdir_p!(path)

      File.write!(
        Path.join(path, Macro.underscore(DAPCodegen.Naming.name(mod)) <> ".ex"),
        source_code
      )
    end

    File.write!(
      Path.join(path, "requests.ex"),
      render_requests(%{
        requests: metamodel.requests,
        prefix: "GenDAP"
      })
    )

    File.write!(
      Path.join(path, "responses.ex"),
      render_responses(%{
        requests: metamodel.requests,
        prefix: "GenDAP"
      })
    )

    File.write!(
      Path.join(path, "events.ex"),
      render_events(%{
        events: metamodel.events,
        prefix: "GenDAP"
      })
    )
  end

  EEx.function_from_string(
    :defp,
    :render_requests,
    """
    # codegen: do not edit
    defmodule <%= @prefix %>.Requests do
      import Schematic

      def new(request) do
        unify(oneof(fn
          <%= for r <- Enum.sort_by(@requests, & &1.command) do %>
            %{"command" => <%= inspect(r.command) %>} -> <%= @prefix %>.Requests.<%= DAPCodegen.Naming.name(r) %>Request.schematic()
          <% end %>
            _ -> {:error, "unexpected request payload"}
        end), request)
      end
    end
    """,
    [:assigns]
  )

  EEx.function_from_string(
    :defp,
    :render_responses,
    """
    # codegen: do not edit
    defmodule <%= @prefix %>.Responses do
      import Schematic

      def new(request) do
        unify(oneof(fn
          <%= for r <- Enum.sort_by(@requests, & &1.command) do %>
            %{"command" => <%= inspect(r.command) %>} -> <%= @prefix %>.Requests.<%= DAPCodegen.Naming.name(r) %>Response.schematic()
          <% end %>
            _ -> {:error, "unexpected response payload"}
        end), request)
      end
    end
    """,
    [:assigns]
  )

  EEx.function_from_string(
    :defp,
    :render_events,
    """
    # codegen: do not edit
    defmodule <%= @prefix %>.Events do
      import Schematic

      def new(event) do
        unify(oneof(fn
          <%= for n <- Enum.sort_by(@events, & &1.event) do %>
            %{"event" => <%= inspect(n.event) %>} -> <%= @prefix %>.Events.<%= DAPCodegen.Naming.name(n) %>.schematic()
          <% end %>
            _ -> {:error, "unexpected event payload"}
        end), event)
      end
    end
    """,
    [:assigns]
  )
end
