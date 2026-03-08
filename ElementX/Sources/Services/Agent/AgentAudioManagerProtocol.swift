//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

/// Manages playing audio cues in response to Matrix reactions from
/// configured voice agent targets.
// sourcery: AutoMockable
@MainActor
protocol AgentAudioManagerProtocol {
    /// Handle a reaction event, playing the corresponding sound if the sender
    /// is the configured voice target for the room.
    func handleReaction(_ emoji: String, from senderID: String, in roomID: String)
    
    /// Play a named sound from the app bundle.
    func playSound(named name: String)
}
