//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import Combine
import Foundation
import MediaPlayer

/// Detects rapid volume button presses for push-to-talk activation.
///
/// Uses KVO on `AVAudioSession.outputVolume`. A rapid press-and-release
/// (volume change within a short window) triggers PTT recording toggle.
///
/// After detecting a press, the volume is silently reset using the system
/// volume slider to avoid hitting 0% or 100%.
///
/// > Warning: Apple does not officially support this mechanism. This is
/// > suitable for ad-hoc/enterprise distribution only.
@MainActor
final class VolumeButtonPTTService: VolumeButtonPTTServiceProtocol {
    private let actionsSubject = PassthroughSubject<PTTAction, Never>()
    var actionsPublisher: AnyPublisher<PTTAction, Never> { actionsSubject.eraseToAnyPublisher() }
    
    private var volumeObservation: NSKeyValueObservation?
    private var lastVolumeChangeTime = Date.distantPast
    private var isRecording = false
    
    /// Hidden MPVolumeView used to silently reset volume after detection.
    private var volumeView: MPVolumeView?
    
    /// Minimum time between volume changes to count as "rapid press" (seconds).
    private let rapidPressThreshold: TimeInterval = 0.3
    
    /// The volume level to reset to after detection.
    private let resetVolume: Float = 0.5
    
    func start() {
        // Create an off-screen MPVolumeView for silent volume reset
        let view = MPVolumeView(frame: .zero)
        view.alpha = 0.001
        volumeView = view
        
        // Save current volume
        let session = AVAudioSession.sharedInstance()
        
        // Observe volume changes via KVO
        volumeObservation = session.observe(\.outputVolume, options: [.new, .old]) { [weak self] _, change in
            Task { @MainActor in
                self?.handleVolumeChange(oldValue: change.oldValue,
                                         newValue: change.newValue)
            }
        }
        
        MXLog.info("Volume button PTT service started")
    }
    
    func stop() {
        volumeObservation?.invalidate()
        volumeObservation = nil
        volumeView = nil
        isRecording = false
        
        MXLog.info("Volume button PTT service stopped")
    }
    
    // MARK: - Private
    
    private func handleVolumeChange(oldValue: Float?, newValue: Float?) {
        guard let oldValue, let newValue, oldValue != newValue else { return }
        
        let now = Date()
        let timeSinceLastChange = now.timeIntervalSince(lastVolumeChangeTime)
        lastVolumeChangeTime = now
        
        // Only trigger on rapid presses (not gradual adjustment)
        guard timeSinceLastChange > 0.05 else {
            // Too fast — probably a programmatic reset
            return
        }
        
        // Toggle recording on each volume button press
        if isRecording {
            actionsSubject.send(.stopRecording)
            isRecording = false
        } else {
            actionsSubject.send(.startRecording)
            isRecording = true
        }
        
        // Silently reset volume to middle to avoid hitting 0% or 100%
        resetVolumeLevel()
    }
    
    private func resetVolumeLevel() {
        guard let volumeView else { return }
        
        // Find the slider within MPVolumeView and set its value
        for subview in volumeView.subviews {
            if let slider = subview as? UISlider {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    slider.value = self.resetVolume
                }
                break
            }
        }
    }
}
