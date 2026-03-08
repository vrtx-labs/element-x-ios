//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import Foundation

/// Plays a continuous silent audio loop to keep AirPods/Bluetooth earbuds
/// connected, and enables Now Playing controls + remote command center
/// responsiveness for PTT features.
///
/// Uses `.playAndRecord` with `.mixWithOthers` so it doesn't interrupt
/// other audio sources.
@MainActor
final class SilentAudioLoopService: SilentAudioLoopServiceProtocol {
    private var audioPlayer: AVAudioPlayer?
    private(set) var isRunning = false
    
    func start() {
        guard !isRunning else { return }
        
        // Generate a 1-second silent WAV in memory
        guard let silentData = generateSilentWAV(durationSeconds: 1.0, sampleRate: 44100) else {
            MXLog.error("Failed to generate silent audio data")
            return
        }
        
        do {
            // Configure session for playback + recording with mixing
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(data: silentData)
            audioPlayer?.numberOfLoops = -1 // Loop forever
            audioPlayer?.volume = 0.0 // Silent
            audioPlayer?.play()
            
            isRunning = true
            MXLog.info("Silent audio loop started")
            
            // Subscribe to interruptions
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleInterruption(_:)),
                name: AVAudioSession.interruptionNotification,
                object: AVAudioSession.sharedInstance()
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRouteChange(_:)),
                name: AVAudioSession.routeChangeNotification,
                object: AVAudioSession.sharedInstance()
            )
        } catch {
            MXLog.error("Failed to start silent audio loop: \(error)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isRunning = false
        
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.interruptionNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.routeChangeNotification,
                                                  object: nil)
        
        MXLog.info("Silent audio loop stopped")
    }
    
    // MARK: - Interruption Handling
    
    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            MXLog.info("Silent audio loop interrupted")
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    audioPlayer?.play()
                    MXLog.info("Silent audio loop resumed after interruption")
                }
            }
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // AirPods disconnected — restart if still needed
            if isRunning {
                audioPlayer?.play()
                MXLog.info("Silent audio loop restarted after route change")
            }
        default:
            break
        }
    }
    
    // MARK: - Silent WAV Generation
    
    /// Generates a silent WAV file in memory.
    private func generateSilentWAV(durationSeconds: Double, sampleRate: Int) -> Data? {
        let numChannels: Int = 1
        let bitsPerSample: Int = 16
        let numSamples = Int(durationSeconds * Double(sampleRate))
        let dataSize = numSamples * numChannels * (bitsPerSample / 8)
        let fileSize = 44 + dataSize // WAV header = 44 bytes
        
        var data = Data(capacity: fileSize)
        
        // RIFF header
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        data.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize - 8).littleEndian) { Array($0) })
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        
        // fmt subchunk
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) }) // Subchunk1Size
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // AudioFormat (PCM)
        data.append(contentsOf: withUnsafeBytes(of: UInt16(numChannels).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        let byteRate = sampleRate * numChannels * (bitsPerSample / 8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Array($0) })
        let blockAlign = numChannels * (bitsPerSample / 8)
        data.append(contentsOf: withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { Array($0) })
        
        // data subchunk (all zeroes = silence)
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })
        data.append(contentsOf: [UInt8](repeating: 0, count: dataSize))
        
        return data
    }
}
