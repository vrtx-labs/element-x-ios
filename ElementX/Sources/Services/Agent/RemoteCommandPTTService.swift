//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MediaPlayer

/// Handles AirPods / Apple Watch remote command center events for PTT:
/// - `togglePlayPauseCommand` → toggle agent audio playback
/// - `nextTrackCommand` → start/stop voice message recording (PTT)
///
/// Also populates `MPNowPlayingInfoCenter` so the Apple Watch shows
/// a controllable Now Playing card.
@MainActor
final class RemoteCommandPTTService: RemoteCommandPTTServiceProtocol {
    private let actionsSubject = PassthroughSubject<PTTAction, Never>()
    var actionsPublisher: AnyPublisher<PTTAction, Never> { actionsSubject.eraseToAnyPublisher() }
    
    private var isRecording = false
    
    func start() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play/Pause → toggle agent voice playback
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.actionsSubject.send(.toggleAgentPlayback)
            }
            return .success
        }
        
        // Next Track → toggle PTT recording
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.isRecording {
                    self.actionsSubject.send(.stopRecording)
                    self.isRecording = false
                } else {
                    self.actionsSubject.send(.startRecording)
                    self.isRecording = true
                }
            }
            return .success
        }
        
        // Set up Now Playing info for Apple Watch
        updateNowPlayingInfo(isRecording: false)
        
        MXLog.info("Remote command PTT service started")
    }
    
    func stop() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        isRecording = false
        
        MXLog.info("Remote command PTT service stopped")
    }
    
    private func updateNowPlayingInfo(isRecording: Bool) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = isRecording ? "Recording..." : "Voice Agent"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Element X"
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
