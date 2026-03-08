//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias VoiceAgentSettingsScreenViewModelType = StateStoreViewModelV2<VoiceAgentSettingsScreenViewState, VoiceAgentSettingsScreenViewAction>

class VoiceAgentSettingsScreenViewModel: VoiceAgentSettingsScreenViewModelType, VoiceAgentSettingsScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<VoiceAgentSettingsScreenViewModelAction, Never> = .init()
    private let roomProxy: JoinedRoomProxyProtocol
    private let settingsStore: VoiceAgentRoomSettingsStore
    
    var actions: AnyPublisher<VoiceAgentSettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomProxy: JoinedRoomProxyProtocol,
         settingsStore: VoiceAgentRoomSettingsStore = VoiceAgentRoomSettingsStore()) {
        self.roomProxy = roomProxy
        self.settingsStore = settingsStore
        
        let settings = settingsStore.settings(for: roomProxy.id)
        let members = roomProxy.membersPublisher.value
            .filter { $0.userID != roomProxy.ownUserID }
            .map { VoiceAgentMemberItem(userID: $0.userID, displayName: $0.displayName, avatarURL: $0.avatarURL) }
        
        super.init(initialViewState: VoiceAgentSettingsScreenViewState(
            roomID: roomProxy.id,
            isEnabled: settings.isEnabled,
            voiceTargetUserID: settings.voiceTargetUserID,
            roomMembers: members
        ))
        
        setupMembersSubscription()
    }
    
    // MARK: - Public
    
    override func process(viewAction: VoiceAgentSettingsScreenViewAction) {
        switch viewAction {
        case .toggleEnabled:
            state.isEnabled.toggle()
            if !state.isEnabled {
                state.voiceTargetUserID = nil
            }
            saveSettings()
        case .selectVoiceTarget(let userID):
            state.voiceTargetUserID = userID
            saveSettings()
        case .clearVoiceTarget:
            state.voiceTargetUserID = nil
            saveSettings()
        }
    }
    
    // MARK: - Private
    
    private func setupMembersSubscription() {
        roomProxy.membersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] members in
                guard let self else { return }
                state.roomMembers = members
                    .filter { $0.userID != roomProxy.ownUserID }
                    .map { VoiceAgentMemberItem(userID: $0.userID, displayName: $0.displayName, avatarURL: $0.avatarURL) }
            }
            .store(in: &cancellables)
    }
    
    private func saveSettings() {
        var settings = settingsStore.settings(for: roomProxy.id)
        settings.isEnabled = state.isEnabled
        settings.voiceTargetUserID = state.voiceTargetUserID
        settingsStore.save(settings, for: roomProxy.id)
    }
}
