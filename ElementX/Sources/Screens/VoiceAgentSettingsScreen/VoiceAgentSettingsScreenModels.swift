//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum VoiceAgentSettingsScreenViewModelAction {
    case dismiss
}

enum VoiceAgentSettingsScreenViewAction {
    case toggleEnabled
    case selectVoiceTarget(userID: String)
    case clearVoiceTarget
}

struct VoiceAgentSettingsScreenViewState: BindableState {
    var roomID: String
    var voiceTargetUserID: String?
    var roomMembers: [VoiceAgentMemberItem]
    var bindings = VoiceAgentSettingsScreenViewStateBindings()
    
    var voiceTargetDisplayName: String? {
        roomMembers.first { $0.userID == voiceTargetUserID }?.displayName
    }
}

struct VoiceAgentSettingsScreenViewStateBindings {
    var isEnabled = false
    var alertInfo: AlertInfo<VoiceAgentSettingsScreenErrorType>?
}

enum VoiceAgentSettingsScreenErrorType: Hashable {
    case saveFailed
}

struct VoiceAgentMemberItem: Identifiable, Equatable {
    var id: String { userID }
    let userID: String
    let displayName: String?
    let avatarURL: URL?
}
