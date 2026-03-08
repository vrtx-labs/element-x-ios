//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreMotion
import Foundation

/// Detects AirPods Pro head gestures using CMHeadphoneMotionManager:
/// - **Nod** (pitch forward then back within threshold) → confirm
/// - **Head shake** (rapid yaw oscillation) → cancel
///
/// Requires `NSMotionUsageDescription` in Info.plist.
@MainActor
final class HeadphoneMotionService: HeadphoneMotionServiceProtocol {
    private let actionsSubject = PassthroughSubject<HeadMotionAction, Never>()
    var actionsPublisher: AnyPublisher<HeadMotionAction, Never> { actionsSubject.eraseToAnyPublisher() }
    
    private let motionManager = CMHeadphoneMotionManager()
    private let operationQueue = OperationQueue()
    
    // Nod detection state
    private var lastPitch: Double = 0
    private var nodForwardDetected = false
    private var nodForwardTime = Date.distantPast
    
    // Head shake detection state
    private var yawSamples = [Double]()
    private let yawSampleWindow = 20 // Number of recent samples to check
    
    /// Pitch threshold for nod detection (radians, ~15°)
    private let nodThreshold: Double = 0.26
    
    /// Yaw oscillation threshold for head shake detection (radians, ~20°)
    private let shakeThreshold: Double = 0.35
    
    /// Maximum time between nod forward and nod back (seconds)
    private let nodMaxDuration: TimeInterval = 0.5
    
    /// Minimum yaw direction changes within the sample window for a shake
    private let shakeMinDirectionChanges = 3
    
    func start() {
        guard CMHeadphoneMotionManager.isDeviceMotionAvailable else {
            MXLog.info("Headphone motion not available on this device")
            return
        }
        
        operationQueue.name = "HeadphoneMotionService"
        operationQueue.maxConcurrentOperationCount = 1
        
        motionManager.startDeviceMotionUpdates(to: operationQueue) { [weak self] motion, error in
            guard let motion, error == nil else {
                if let error {
                    MXLog.error("Headphone motion error: \(error)")
                }
                return
            }
            
            Task { @MainActor in
                self?.processMotion(motion)
            }
        }
        
        MXLog.info("Headphone motion service started")
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
        nodForwardDetected = false
        yawSamples.removeAll()
        
        MXLog.info("Headphone motion service stopped")
    }
    
    // MARK: - Private
    
    private func processMotion(_ motion: CMDeviceMotion) {
        let pitch = motion.attitude.pitch
        let yaw = motion.attitude.yaw
        
        detectNod(pitch: pitch)
        detectHeadShake(yaw: yaw)
    }
    
    private func detectNod(pitch: Double) {
        let deltaPitch = pitch - lastPitch
        lastPitch = pitch
        
        if !nodForwardDetected && deltaPitch < -nodThreshold {
            // Forward nod detected
            nodForwardDetected = true
            nodForwardTime = Date()
        } else if nodForwardDetected {
            let elapsed = Date().timeIntervalSince(nodForwardTime)
            
            if elapsed > nodMaxDuration {
                // Too slow — reset
                nodForwardDetected = false
            } else if deltaPitch > nodThreshold {
                // Return nod detected — complete nod gesture!
                nodForwardDetected = false
                actionsSubject.send(.nod)
                MXLog.info("Head nod gesture detected")
            }
        }
    }
    
    private func detectHeadShake(yaw: Double) {
        yawSamples.append(yaw)
        if yawSamples.count > yawSampleWindow {
            yawSamples.removeFirst()
        }
        
        guard yawSamples.count >= yawSampleWindow else { return }
        
        // Count direction changes in the yaw samples
        var directionChanges = 0
        var lastDelta: Double = 0
        
        for i in 1..<yawSamples.count {
            let delta = yawSamples[i] - yawSamples[i - 1]
            if abs(delta) > 0.01 { // Ignore noise
                if lastDelta != 0 && (delta > 0) != (lastDelta > 0) {
                    directionChanges += 1
                }
                lastDelta = delta
            }
        }
        
        // Check if the yaw range exceeds threshold
        let yawRange = (yawSamples.max() ?? 0) - (yawSamples.min() ?? 0)
        
        if directionChanges >= shakeMinDirectionChanges && yawRange > shakeThreshold {
            yawSamples.removeAll() // Reset to avoid repeated triggers
            actionsSubject.send(.headShake)
            MXLog.info("Head shake gesture detected")
        }
    }
}
