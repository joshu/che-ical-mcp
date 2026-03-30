import Foundation
import MCP

/// Handles --cli mode: parse CLI args or stdin JSON, dispatch to tool handler, print result.
enum CLIRunner {

    enum CLIError: LocalizedError {
        case missingToolName
        case danglingKey(String)
        case missingToolField
        case invalidJSON(String)

        var errorDescription: String? {
            switch self {
            case .missingToolName:
                return "Missing tool name. Usage: CheICalMCP --cli <tool_name> [--key value ...]"
            case .danglingKey(let key):
                return "Argument '--\(key)' has no value. All arguments require a value."
            case .missingToolField:
                return "JSON input must contain a 'tool' field. Expected: {\"tool\":\"...\",\"arguments\":{...}}"
            case .invalidJSON(let detail):
                return "Invalid JSON input: \(detail)"
            }
        }
    }

    // MARK: - Flag-based arg parsing

    /// Parse `--cli tool_name --key1 value1 --key2 value2` into (toolName, arguments).
    /// Returns string-keyed dictionary; values are always strings (handlers use .stringValue).
    static func parseArgs(_ args: [String]) throws -> (tool: String, arguments: [String: String]) {
        // Find --cli index, tool name is the next arg
        guard let cliIndex = args.firstIndex(of: "--cli"),
              cliIndex + 1 < args.count
        else {
            throw CLIError.missingToolName
        }

        let toolName = args[cliIndex + 1]

        // Remaining args after tool name are --key value pairs
        var arguments: [String: String] = [:]
        var i = cliIndex + 2
        while i < args.count {
            let arg = args[i]
            guard arg.hasPrefix("--") else {
                i += 1
                continue
            }
            let key = String(arg.dropFirst(2))
            guard i + 1 < args.count else {
                throw CLIError.danglingKey(key)
            }
            arguments[key] = args[i + 1]
            i += 2
        }

        return (toolName, arguments)
    }

    // MARK: - JSON stdin parsing

    /// Parse `{"tool":"...","arguments":{...}}` JSON string into (toolName, arguments).
    static func parseJSONInput(_ input: String) throws -> (tool: String, arguments: [String: String]) {
        guard let data = input.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw CLIError.invalidJSON("could not parse as JSON object")
        }

        guard let toolName = json["tool"] as? String else {
            throw CLIError.missingToolField
        }

        var arguments: [String: String] = [:]
        if let args = json["arguments"] as? [String: Any] {
            for (key, value) in args {
                // Convert all values to strings for consistency with CLI arg parsing
                if let str = value as? String {
                    arguments[key] = str
                } else if let num = value as? NSNumber {
                    // Distinguish bool from number
                    if CFGetTypeID(num) == CFBooleanGetTypeID() {
                        arguments[key] = num.boolValue ? "true" : "false"
                    } else {
                        arguments[key] = "\(num)"
                    }
                } else if value is NSNull {
                    // Skip null values
                } else {
                    // Arrays, objects → serialize back to JSON string
                    if let jsonData = try? JSONSerialization.data(withJSONObject: value),
                       let jsonStr = String(data: jsonData, encoding: .utf8)
                    {
                        arguments[key] = jsonStr
                    }
                }
            }
        }

        return (toolName, arguments)
    }

    // MARK: - Convert to MCP Value

    /// Convert string dictionary to MCP Value dictionary for executeToolCall.
    static func toMCPArguments(_ args: [String: String]) -> [String: Value] {
        var result: [String: Value] = [:]
        for (key, value) in args {
            result[key] = .string(value)
        }
        return result
    }

    // MARK: - Run

    /// Run CLI mode: detect input source, parse, dispatch, print result.
    static func run(server: CheICalMCPServer, args: [String]) async {
        do {
            let toolName: String
            let arguments: [String: String]

            // Detect if stdin has data (piped JSON mode)
            if isatty(fileno(stdin)) == 0 {
                let inputData = FileHandle.standardInput.readDataToEndOfFile()
                guard let input = String(data: inputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !input.isEmpty
                else {
                    // No stdin data, fall back to flag parsing
                    (toolName, arguments) = try parseArgs(args)
                    let mcpArgs = toMCPArguments(arguments)
                    let result = try await server.executeToolCall(name: toolName, arguments: mcpArgs)
                    print(result)
                    return
                }
                (toolName, arguments) = try parseJSONInput(input)
            } else {
                (toolName, arguments) = try parseArgs(args)
            }

            let mcpArgs = toMCPArguments(arguments)
            let result = try await server.executeToolCall(name: toolName, arguments: mcpArgs)
            print(result)
        } catch {
            // Output error as JSON for machine readability
            let errorJSON: [String: Any] = [
                "error": true,
                "message": error.localizedDescription,
            ]
            if let data = try? JSONSerialization.data(withJSONObject: errorJSON, options: [.sortedKeys]),
               let str = String(data: data, encoding: .utf8)
            {
                print(str)
            } else {
                print("{\"error\":true,\"message\":\"\(error.localizedDescription)\"}")
            }
            exit(1)
        }
    }
}
