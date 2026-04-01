import EventKit
import Foundation

// MARK: - Participant Formatting Utilities

/// Extract email address from EKParticipant URL.
/// Strips "mailto:" prefix (case-insensitive). Non-mailto URLs are returned as-is.
func extractEmailFromParticipantURL(_ url: URL) -> String {
    let urlString = url.absoluteString
    if urlString.lowercased().hasPrefix("mailto:") {
        return String(urlString.dropFirst("mailto:".count))
    }
    return urlString
}

/// Map EKParticipantRole to human-readable string.
func participantRoleString(_ role: EKParticipantRole) -> String {
    switch role {
    case .unknown: return "unknown"
    case .required: return "required"
    case .optional: return "optional"
    case .chair: return "chair"
    case .nonParticipant: return "non_participant"
    @unknown default: return "unknown"
    }
}

/// Map EKParticipantStatus to human-readable string.
func participantStatusString(_ status: EKParticipantStatus) -> String {
    switch status {
    case .unknown: return "unknown"
    case .pending: return "pending"
    case .accepted: return "accepted"
    case .declined: return "declined"
    case .tentative: return "tentative"
    case .delegated: return "delegated"
    case .completed: return "completed"
    case .inProcess: return "in_process"
    @unknown default: return "unknown"
    }
}

/// Map EKParticipantType to human-readable string.
func participantTypeString(_ type: EKParticipantType) -> String {
    switch type {
    case .unknown: return "unknown"
    case .person: return "person"
    case .room: return "room"
    case .resource: return "resource"
    case .group: return "group"
    @unknown default: return "unknown"
    }
}

/// Format an EKParticipant as a dictionary for JSON output.
/// Handles nil name (sets to NSNull for JSON null) and email extraction.
func formatParticipant(_ participant: EKParticipant) -> [String: Any] {
    var dict: [String: Any] = [
        "email": extractEmailFromParticipantURL(participant.url),
        "role": participantRoleString(participant.participantRole),
        "status": participantStatusString(participant.participantStatus),
        "type": participantTypeString(participant.participantType),
        "is_current_user": participant.isCurrentUser
    ]
    if let name = participant.name {
        dict["name"] = name
    } else {
        dict["name"] = NSNull()
    }
    return dict
}

/// Format attendees and organizer from an EKEvent.
/// Returns nil if event has neither attendees nor organizer.
func formatAttendeesInfo(_ event: EKEvent) -> (attendees: [[String: Any]]?, organizer: [String: Any]?) {
    let attendees: [[String: Any]]? = event.attendees.map { participants in
        participants.map { formatParticipant($0) }
    }

    let organizer: [String: Any]? = event.organizer.map { org in
        [
            "name": org.name as Any? ?? NSNull(),
            "email": extractEmailFromParticipantURL(org.url),
            "is_current_user": org.isCurrentUser
        ]
    }

    return (attendees, organizer)
}
