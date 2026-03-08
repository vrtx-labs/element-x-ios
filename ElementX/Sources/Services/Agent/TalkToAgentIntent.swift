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
/// Usage: "Hey Siri, talk to my agent in [room name]"
/// Opens the specified room and arms PTT recording.
@available(iOS 16.0, *)
struct TalkToAgentIntent: AppIntent {
    static var title: LocalizedStringResource = "Talk to Agent"
    static var description = IntentDescription("Start a voice conversation with your agent in a Matrix room.")
    
    @Parameter(title: "Room Name")
    var roomName: String
    
    static var openAppWhenRun = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Post a notification that the app can observe to navigate to the room
        NotificationCenter.default.post(
            name: .voiceAgentIntentTriggered,
            object: nil,
            userInfo: ["roomName": roomName]
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
                "Talk to my agent in \(\.$roomName) with \(.applicationName)",
                "Start voice agent in \(\.$roomName) with \(.applicationName)",
                "Open agent \(\.$roomName) in \(.applicationName)"
            ],
            shortTitle: "Talk to Agent",
            systemImageName: "mic.fill"
        )
    }
}

extension Notification.Name {
    static let voiceAgentIntentTriggered = Notification.Name("voiceAgentIntentTriggered")
}
