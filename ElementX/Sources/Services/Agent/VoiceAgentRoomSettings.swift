//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Per-room voice agent settings, stored in UserDefaults keyed by room ID.
/// Allows any user in a room to be selected as the voice agent target
/// for autoplay, reaction sound cues, and PTT features.
struct VoiceAgentRoomSettings: Codable, Equatable {
    /// Whether voice agent mode is enabled for this room.
    var isEnabled: Bool = false
    /// The Matrix user ID of the room member designated as the voice target.
    var voiceTargetUserID: String?
    /// Mapping of emoji strings to sound file names (without extension).
    /// e.g. ["🤔": "processing", "✅": "ready"]
    var reactionSoundMap: [String: String] = Self.defaultSoundMap
    
    static let defaultSoundMap: [String: String] = [
        "🤔": "processing",
        "✅": "ready",
        "💭": "thinking",
        "❌": "error"
    ]
}

/// Manages loading and saving of per-room voice agent settings.
final class VoiceAgentRoomSettingsStore {
    private static let storeKey = "voiceAgentRoomSettings"
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func settings(for roomID: String) -> VoiceAgentRoomSettings {
        guard let data = settingsDictionary()[roomID],
              let decoded = try? JSONDecoder().decode(VoiceAgentRoomSettings.self, from: data) else {
            return VoiceAgentRoomSettings()
        }
        return decoded
    }
    
    func save(_ settings: VoiceAgentRoomSettings, for roomID: String) {
        var dictionary = settingsDictionary()
        if let encoded = try? JSONEncoder().encode(settings) {
            dictionary[roomID] = encoded
        }
        userDefaults.set(dictionary, forKey: Self.storeKey)
    }
    
    // MARK: - Private
    
    private func settingsDictionary() -> [String: Data] {
        userDefaults.dictionary(forKey: Self.storeKey) as? [String: Data] ?? [:]
    }
}
