//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

/// Monitors the timeline for new voice messages from the configured voice
/// agent target and auto-plays them sequentially. Works alongside the
/// existing `TimelineInteractionHandler` playback infrastructure.
@MainActor
final class VoiceMessageAutoplayService {
    private let roomProxy: JoinedRoomProxyProtocol
    private let timelineController: TimelineControllerProtocol
    private let settingsStore: VoiceAgentRoomSettingsStore
    private let appSettings: AppSettings
    
    /// Closure invoked to trigger playback of a voice message by its item ID.
    /// This is set by the owning TimelineInteractionHandler/RoomScreenCoordinator.
    var playbackHandler: ((TimelineItemIdentifier) async -> Void)?
    
    /// Tracks IDs that have already been autoplayed to avoid replaying on re-render.
    private var autoplayedItemIDs = Set<TimelineItemIdentifier>()
    
    /// Queue of item IDs waiting to be autoplayed.
    private var autoplayQueue = [TimelineItemIdentifier]()
    
    /// Whether a voice message is currently being played by the autoplay service.
    private(set) var isAutoplayActive = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(roomProxy: JoinedRoomProxyProtocol,
         timelineController: TimelineControllerProtocol,
         settingsStore: VoiceAgentRoomSettingsStore = VoiceAgentRoomSettingsStore(),
         appSettings: AppSettings) {
        self.roomProxy = roomProxy
        self.timelineController = timelineController
        self.settingsStore = settingsStore
        self.appSettings = appSettings
    }
    
    /// Start monitoring the timeline for voice messages from the configured target.
    func start() {
        let settings = settingsStore.settings(for: roomProxy.id)
        
        guard settings.isEnabled,
              let targetUserID = settings.voiceTargetUserID,
              appSettings.globalAutoplayEnabled else {
            MXLog.verbose("Voice message autoplay not configured for room \(roomProxy.id)")
            return
        }
        
        // Monitor timeline updates via callbacks
        timelineController.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                switch callback {
                case .updatedTimelineItems(let timelineItems, _):
                    self?.processTimelineItems(timelineItems, targetUserID: targetUserID)
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Process any existing items
        processTimelineItems(timelineController.timelineItems, targetUserID: targetUserID)
    }
    
    /// Stop monitoring and clear the queue.
    func stop() {
        cancellables.removeAll()
        autoplayQueue.removeAll()
        isAutoplayActive = false
    }
    
    /// Called when a voice message finishes playing. Plays the next queued item if any.
    func handlePlaybackFinished() {
        isAutoplayActive = false
        playNextInQueue()
    }
    
    // MARK: - Private
    
    private func processTimelineItems(_ items: [RoomTimelineItemProtocol], targetUserID: String) {
        for item in items {
            guard let voiceItem = item as? VoiceMessageRoomTimelineItem,
                  voiceItem.sender.id == targetUserID else {
                continue
            }
            
            let itemID = voiceItem.id
            
            // Skip if already autoplayed
            guard !autoplayedItemIDs.contains(itemID) else {
                continue
            }
            
            autoplayedItemIDs.insert(itemID)
            autoplayQueue.append(itemID)
        }
        
        // Start playing if nothing is currently in progress
        if !isAutoplayActive {
            playNextInQueue()
        }
    }
    
    private func playNextInQueue() {
        guard !autoplayQueue.isEmpty else {
            return
        }
        
        let nextItemID = autoplayQueue.removeFirst()
        isAutoplayActive = true
        
        Task { [weak self] in
            await self?.playbackHandler?(nextItemID)
        }
    }
}
