# DAPCodegen

Library to generate DAP protocol code for [gen_dap](https://github.com/elixir-lsp/gen_dap).

## Usage

For DAP code generation:

```bash
elixir -e 'Mix.install([{:dap_codegen, github: "elixir-lsp/dap_codegen"}]); DAPCodegen.generate(System.argv())' -- --path ./path/for/files
```

## Schema Files

### DAP Schema

To update the debugAdapterProtocol.json, you can run the following:

```bash
curl --location 'https://microsoft.github.io/debug-adapter-protocol/debugAdapterProtocol.json' | jq . > priv/debugAdapterProtocol.json
```

## Schema description

### Request

A request in the Debug Adapter Protocol (DAP) is a message sent from the client (IDE) to the debug adapter. It typically includes the following features:
Type: The type of message, which is always "request".
Seq: A sequence number to identify the message.
Command: The specific command being requested (e.g., "initialize", "launch").
Arguments: A set of parameters required for the command.

```json
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "type": "object",
  "properties": {
    "type": { "type": "string", "enum": ["request"] },
    "seq": { "type": "integer" },
    "command": { "type": "string" },
    "arguments": { "type": [ "array", "boolean", "integer", "null", "number" , "object", "string" ] }
  },
  "required": ["type", "seq", "command"]
}
```

### Event

An event is a notification sent from the debug adapter to the client, indicating a change in state or an occurrence of interest.

```json
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "type": "object",
  "properties": {
    "type": { "type": "string", "enum": ["event"] },
    "seq": { "type": "integer" },
    "event": { "type": "string" },
    "body": { "type": [ "array", "boolean", "integer", "null", "number" , "object", "string" ] }
  },
  "required": ["type", "seq", "event"]
}
```

### Response

A response is sent from the debug adapter back to the client in reply to a request.

```json
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "type": "object",
  "properties": {
    "type": { "type": "string", "enum": ["response"] },
    "seq": { "type": "integer" },
    "request_seq": { "type": "integer" },
    "success": { "type": "boolean" },
    "command": { "type": "string" },
    "message": { "type": "string" },
    "body": { "type": [ "array", "boolean", "integer", "null", "number" , "object", "string" ] }
  },
  "required": ["type", "seq", "request_seq", "success", "command"]
}
```

### Error Response

An error response indicates that a request could not be processed successfully.

```json
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "type": "object",
  "properties": {
    "type": { "type": "string", "enum": ["response"] },
    "seq": { "type": "integer" },
    "request_seq": { "type": "integer" },
    "success": { "type": "boolean", "enum": [false] },
    "command": { "type": "string" },
    "body": {
      "type": "object",
      "properties": {
        "error": {
          "type": "object",
          "properties": {
            "id": { "type": "integer" },
            "format": { "type": "string" }
            "variables": {
              "type": "object",
              "additionalProperties": {
                "type": "string"
              }
            },
            "sendTelemetry": {
              "type": "boolean"
            },
            "showUser": {
              "type": "boolean"
            },
            "url": {
              "type": "string"
            },
            "urlLabel": {
              "type": "string"
            }
          },
          "required": ["id", "format"]
        }
      },
      "required": ["error"]
    }
  },
  "required": ["type", "seq", "request_seq", "success", "command", "body"]
}
```

## Credits

This library is inspired by [lsp_codegen](https://github.com/elixir-tools/lsp_codegen) by Mitchell Hanberg.
