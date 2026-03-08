//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AppIntents
import Foundation

/// Siri App Intent to quickly start a voice agent conversation.
///
/// Usage: "Hey Siri, talk to my agent"
/// Opens the app and arms PTT recording in the most recently configured voice agent room.
@available(iOS 16.0, *)
struct TalkToAgentIntent: AppIntent {
    static var title: LocalizedStringResource = "Talk to Agent"
    static var description = IntentDescription("Start a voice conversation with your agent.")
    
    @Parameter(title: "Room Name")
    var roomName: String?
    
    static var openAppWhenRun = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Post a notification that the app can observe to navigate to the room
        var userInfo = [String: Any]()
        if let roomName {
            userInfo["roomName"] = roomName
        }
        
        NotificationCenter.default.post(
            name: .voiceAgentIntentTriggered,
            object: nil,
            userInfo: userInfo
        )
        
        return .result()
    }
}

/// App shortcuts for quick Siri voice agent access.
@available(iOS 16.0, *)
struct AgentAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TalkToAgentIntent(),
            phrases: [
                "Talk to my agent with \(.applicationName)",
                "Start voice agent with \(.applicationName)"
            ],
            shortTitle: "Talk to Agent",
            systemImageName: "mic.fill"
        )
    }
}

extension Notification.Name {
    static let voiceAgentIntentTriggered = Notification.Name("voiceAgentIntentTriggered")
}
