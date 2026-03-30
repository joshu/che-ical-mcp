import XCTest

@testable import CheICalMCP

final class CLIRunnerTests: XCTestCase {

    // MARK: - Flag-based arg parsing

    func testParseFlagArgs() throws {
        let args = ["--cli", "list_events", "--start_date", "2026-03-29", "--end_date", "2026-03-30"]
        let (tool, arguments) = try CLIRunner.parseArgs(args)
        XCTAssertEqual(tool, "list_events")
        XCTAssertEqual(arguments["start_date"], "2026-03-29")
        XCTAssertEqual(arguments["end_date"], "2026-03-30")
    }

    func testParseFlagArgsNoArguments() throws {
        let args = ["--cli", "list_calendars"]
        let (tool, arguments) = try CLIRunner.parseArgs(args)
        XCTAssertEqual(tool, "list_calendars")
        XCTAssertTrue(arguments.isEmpty)
    }

    func testParseFlagArgsBooleanFlag() throws {
        let args = ["--cli", "delete_events_batch", "--dry_run", "true", "--calendar_name", "Work"]
        let (tool, arguments) = try CLIRunner.parseArgs(args)
        XCTAssertEqual(tool, "delete_events_batch")
        XCTAssertEqual(arguments["dry_run"], "true")
        XCTAssertEqual(arguments["calendar_name"], "Work")
    }

    func testParseFlagArgsMissingToolName() {
        let args = ["--cli"]
        XCTAssertThrowsError(try CLIRunner.parseArgs(args)) { error in
            let msg = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            XCTAssertTrue(msg.contains("tool name") || msg.contains("Tool"), "Error should mention missing tool name, got: \(msg)")
        }
    }

    func testParseFlagArgsDanglingKey() {
        let args = ["--cli", "list_events", "--start_date"]
        XCTAssertThrowsError(try CLIRunner.parseArgs(args)) { error in
            let msg = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            XCTAssertTrue(msg.contains("start_date"), "Error should mention the dangling key, got: \(msg)")
        }
    }

    // MARK: - JSON stdin parsing

    func testParseJSONStdin() throws {
        let json = #"{"tool":"list_calendars","arguments":{}}"#
        let (tool, arguments) = try CLIRunner.parseJSONInput(json)
        XCTAssertEqual(tool, "list_calendars")
        XCTAssertTrue(arguments.isEmpty)
    }

    func testParseJSONStdinWithArguments() throws {
        let json = #"{"tool":"list_events","arguments":{"start_date":"2026-03-29","end_date":"2026-03-30"}}"#
        let (tool, arguments) = try CLIRunner.parseJSONInput(json)
        XCTAssertEqual(tool, "list_events")
        XCTAssertEqual(arguments["start_date"], "2026-03-29")
        XCTAssertEqual(arguments["end_date"], "2026-03-30")
    }

    func testParseJSONStdinMissingTool() {
        let json = #"{"arguments":{}}"#
        XCTAssertThrowsError(try CLIRunner.parseJSONInput(json)) { error in
            let msg = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            XCTAssertTrue(msg.contains("tool"), "Error should mention missing tool field, got: \(msg)")
        }
    }

    func testParseJSONStdinMalformed() {
        let json = "not json at all"
        XCTAssertThrowsError(try CLIRunner.parseJSONInput(json))
    }

    // MARK: - Help message

    func testHelpMessageIncludesCLIFlag() {
        let help = AppVersion.helpMessage
        XCTAssertTrue(help.contains("--cli"), "Help message should document the --cli flag")
    }
}
