defprotocol DAPCodegen.Codegen do
  def to_string(type, metamodel)
end

defprotocol DAPCodegen.Schematic do
  def to_string(type, metamodel)
end

defprotocol DAPCodegen.Naming do
  def name(type)
end
