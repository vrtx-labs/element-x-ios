//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MediaPlayer

/// Protocol for a service that detects volume button presses
/// for push-to-talk activation.
// sourcery: AutoMockable
@MainActor
protocol VolumeButtonPTTServiceProtocol {
    /// Publisher of PTT actions triggered by volume button presses.
    var actionsPublisher: AnyPublisher<PTTAction, Never> { get }
    /// Start listening for volume button presses.
    func start()
    /// Stop listening for volume button presses.
    func stop()
}
