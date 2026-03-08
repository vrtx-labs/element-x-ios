//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MediaPlayer

/// Actions emitted by the PTT services.
enum PTTAction: Equatable {
    /// Start recording a voice message for PTT.
    case startRecording
    /// Stop recording and send the voice message.
    case stopRecording
    /// Toggle play/pause of the agent's last voice message.
    case toggleAgentPlayback
}

/// Protocol for a service that handles AirPods / Apple Watch
/// remote command center push-to-talk gestures.
// sourcery: AutoMockable
@MainActor
protocol RemoteCommandPTTServiceProtocol {
    /// Publisher of PTT actions triggered by remote commands.
    var actionsPublisher: AnyPublisher<PTTAction, Never> { get }
    /// Start listening for remote commands.
    func start()
    /// Stop listening for remote commands.
    func stop()
}
