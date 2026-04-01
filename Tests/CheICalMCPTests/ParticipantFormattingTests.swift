import XCTest
@testable import CheICalMCP

/// Tests for participant formatting utilities (email extraction, enum mapping)
final class ParticipantFormattingTests: XCTestCase {

    // MARK: - Email Extraction

    func testExtractEmailFromMailtoURL() {
        let url = URL(string: "mailto:user@example.com")!
        XCTAssertEqual(extractEmailFromParticipantURL(url), "user@example.com")
    }

    func testExtractEmailFromMailtoURLWithPlus() {
        let url = URL(string: "mailto:user+tag@example.com")!
        XCTAssertEqual(extractEmailFromParticipantURL(url), "user+tag@example.com")
    }

    func testExtractEmailFromNonMailtoURL() {
        let url = URL(string: "https://example.com/user")!
        XCTAssertEqual(extractEmailFromParticipantURL(url), "https://example.com/user")
    }

    func testExtractEmailFromMailtoURLUpperCase() {
        let url = URL(string: "MAILTO:Admin@Company.com")!
        XCTAssertEqual(extractEmailFromParticipantURL(url), "Admin@Company.com")
    }

    // MARK: - Role Mapping

    func testParticipantRoleMapping() {
        XCTAssertEqual(participantRoleString(.unknown), "unknown")
        XCTAssertEqual(participantRoleString(.required), "required")
        XCTAssertEqual(participantRoleString(.optional), "optional")
        XCTAssertEqual(participantRoleString(.chair), "chair")
        XCTAssertEqual(participantRoleString(.nonParticipant), "non_participant")
    }

    // MARK: - Status Mapping

    func testParticipantStatusMapping() {
        XCTAssertEqual(participantStatusString(.unknown), "unknown")
        XCTAssertEqual(participantStatusString(.pending), "pending")
        XCTAssertEqual(participantStatusString(.accepted), "accepted")
        XCTAssertEqual(participantStatusString(.declined), "declined")
        XCTAssertEqual(participantStatusString(.tentative), "tentative")
        XCTAssertEqual(participantStatusString(.delegated), "delegated")
        XCTAssertEqual(participantStatusString(.completed), "completed")
        XCTAssertEqual(participantStatusString(.inProcess), "in_process")
    }

    // MARK: - Type Mapping

    func testParticipantTypeMapping() {
        XCTAssertEqual(participantTypeString(.unknown), "unknown")
        XCTAssertEqual(participantTypeString(.person), "person")
        XCTAssertEqual(participantTypeString(.room), "room")
        XCTAssertEqual(participantTypeString(.resource), "resource")
        XCTAssertEqual(participantTypeString(.group), "group")
    }
}
