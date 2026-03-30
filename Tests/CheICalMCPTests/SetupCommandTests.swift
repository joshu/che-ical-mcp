import XCTest

@testable import CheICalMCP

final class SetupCommandTests: XCTestCase {

    // MARK: - Help Message

    func testHelpMessageIncludesSetupFlag() {
        let help = AppVersion.helpMessage
        XCTAssertTrue(help.contains("--setup"), "Help message should document the --setup flag")
    }

    // MARK: - Launchd Detection

    func testIsLaunchdSessionDetection() {
        // EventKitManager.isLaunchdSession should be a static property we can read
        // On a normal test runner, it should be false (not running under launchd)
        XCTAssertFalse(EventKitManager.isLaunchdSession, "Test runner should not be detected as launchd session")
    }

    // MARK: - Error Messages

    func testAccessDeniedLaunchdMessage() {
        let error = EventKitError.accessDenied(type: "Calendar", isSSH: false, isLaunchd: true)
        let message = error.errorDescription ?? ""
        XCTAssertTrue(message.contains("launchd"), "Error should mention launchd")
        XCTAssertTrue(message.contains("--setup"), "Error should mention --setup workaround")
    }

    func testAccessDeniedSSHMessageUnchanged() {
        let error = EventKitError.accessDenied(type: "Calendar", isSSH: true, isLaunchd: false)
        let message = error.errorDescription ?? ""
        XCTAssertTrue(message.contains("SSH"), "SSH error should still mention SSH")
    }

    func testAccessDeniedNormalMessage() {
        let error = EventKitError.accessDenied(type: "Calendar", isSSH: false, isLaunchd: false)
        let message = error.errorDescription ?? ""
        XCTAssertTrue(message.contains("System Settings"), "Normal error should mention System Settings")
        XCTAssertFalse(message.contains("launchd"), "Normal error should not mention launchd")
        XCTAssertFalse(message.contains("SSH"), "Normal error should not mention SSH")
    }
}
