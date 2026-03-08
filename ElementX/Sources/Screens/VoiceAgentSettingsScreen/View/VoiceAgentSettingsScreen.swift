//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct VoiceAgentSettingsScreen: View {
    @State private var context: VoiceAgentSettingsScreenViewModelType.Context
    
    init(context: VoiceAgentSettingsScreenViewModelType.Context) {
        _context = State(wrappedValue: context)
    }
    
    var body: some View {
        Form {
            enableSection
            
            if context.isEnabled {
                voiceTargetSection
            }
        }
        .compoundList()
        .navigationTitle("Voice Agent Mode")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
    }
    
    // MARK: - Sections
    
    private var enableSection: some View {
        Section {
            ListRow(label: .default(title: "Voice Agent Mode",
                                    icon: \.micOn),
                    kind: .toggle($context.isEnabled))
                .onChange(of: context.isEnabled) { _, _ in
                    context.send(viewAction: .toggleEnabled)
                }
        } footer: {
            Text("Enable to select a room member as a voice agent target. Their voice messages will autoplay and reactions will trigger sound cues.")
                .compoundListSectionFooter()
        }
    }
    
    private var voiceTargetSection: some View {
        Section {
            if let targetUserID = context.viewState.voiceTargetUserID,
               let displayName = context.viewState.voiceTargetDisplayName {
                ListRow(label: .default(title: displayName,
                                        description: targetUserID,
                                        icon: \.userProfile),
                        kind: .button {
                            context.send(viewAction: .clearVoiceTarget)
                        })
            }
            
            ForEach(context.viewState.roomMembers) { member in
                let isSelected = member.userID == context.viewState.voiceTargetUserID
                ListRow(label: .default(title: member.displayName ?? member.userID,
                                        icon: \.userProfile),
                        details: isSelected ? .icon(\.check) : nil,
                        kind: .button {
                            context.send(viewAction: .selectVoiceTarget(userID: member.userID))
                        })
            }
        } header: {
            Text("Voice Target")
                .compoundListSectionHeader()
        } footer: {
            Text("Select the room member whose voice messages will autoplay and whose reactions will trigger audio cues.")
                .compoundListSectionFooter()
        }
    }
}

