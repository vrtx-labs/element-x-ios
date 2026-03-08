//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import Combine
import Foundation

/// Protocol for a service that maintains a silent audio loop to keep
/// AirPods/Bluetooth connected and enable Now Playing + remote command
/// responsiveness.
// sourcery: AutoMockable
@MainActor
protocol SilentAudioLoopServiceProtocol {
    /// Start the silent audio loop.
    func start()
    /// Stop the silent audio loop.
    func stop()
    /// Whether the loop is currently running.
    var isRunning: Bool { get }
}
