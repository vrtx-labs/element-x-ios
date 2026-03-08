//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A single option in an agent's structured quick actions response.
struct QuickActionOption: Identifiable, Equatable {
    let id: String
    let emoji: String
    let label: String
    let value: String
    
    init(id: String = UUID().uuidString, emoji: String, label: String, value: String) {
        self.id = id
        self.emoji = emoji
        self.label = label
        self.value = value
    }
}

/// A timeline item representing structured quick actions from the agent.
/// Displayed as a bottom sheet or inline card with selectable options.
struct QuickActionsRoomTimelineItem: Equatable {
    let id: TimelineItemIdentifier
    let senderID: String
    let timestamp: Date
    let prompt: String
    let options: [QuickActionOption]
    
    /// The event ID of the message this quick actions card is attached to.
    let sourceEventID: String?
}
