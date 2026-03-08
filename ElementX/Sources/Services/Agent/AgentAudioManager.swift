//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import Foundation

/// Plays short audio cues when the configured voice agent target sends
/// emoji reactions in a room. Uses `.ambient` category so it never
/// steals audio focus from other apps.
@MainActor
final class AgentAudioManager: AgentAudioManagerProtocol {
    private var audioPlayer: AVAudioPlayer?
    private let settingsStore: VoiceAgentRoomSettingsStore
    
    init(settingsStore: VoiceAgentRoomSettingsStore = VoiceAgentRoomSettingsStore()) {
        self.settingsStore = settingsStore
    }
    
    func handleReaction(_ emoji: String, from senderID: String, in roomID: String) {
        let settings = settingsStore.settings(for: roomID)
        
        // Only respond to reactions from the configured voice target
        guard settings.isEnabled,
              let targetUserID = settings.voiceTargetUserID,
              senderID == targetUserID else {
            return
        }
        
        // Look up the sound name for this emoji
        guard let soundName = settings.reactionSoundMap[emoji] else {
            MXLog.verbose("No sound mapped for reaction \(emoji) in room \(roomID)")
            return
        }
        
        playSound(named: soundName)
    }
    
    func playSound(named name: String) {
        // Try common audio extensions
        let extensions = ["mp3", "wav", "m4a", "aiff", "caf"]
        
        var url: URL?
        for ext in extensions {
            if let foundURL = Bundle.main.url(forResource: name, withExtension: ext) {
                url = foundURL
                break
            }
        }
        
        guard let soundURL = url else {
            MXLog.error("Sound file not found: \(name)")
            return
        }
        
        do {
            // Configure session for ambient playback (doesn't interrupt other audio)
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            MXLog.error("Failed to play sound \(name): \(error)")
        }
    }
}
