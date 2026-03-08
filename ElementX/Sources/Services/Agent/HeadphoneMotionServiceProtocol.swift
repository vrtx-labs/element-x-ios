//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreMotion
import Foundation

/// Actions emitted by the headphone motion service based on head gestures.
enum HeadMotionAction: Equatable {
    /// User nodded (pitch forward then back) — "confirm" gesture
    case nod
    /// User shook head (rapid yaw oscillation) — "cancel" gesture
    case headShake
}

/// Protocol for a service that detects AirPods Pro head gestures
/// using CMHeadphoneMotionManager.
// sourcery: AutoMockable
@MainActor
protocol HeadphoneMotionServiceProtocol {
    /// Publisher of detected head gestures.
    var actionsPublisher: AnyPublisher<HeadMotionAction, Never> { get }
    /// Start monitoring head motion.
    func start()
    /// Stop monitoring head motion.
    func stop()
}
