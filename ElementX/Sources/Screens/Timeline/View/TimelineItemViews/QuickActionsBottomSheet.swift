//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// A bottom sheet or inline card presenting structured quick actions
/// from the voice agent. Users tap an option to send the corresponding
/// reaction/message.
struct QuickActionsBottomSheet: View {
    let prompt: String
    let options: [QuickActionOption]
    let onSelect: (QuickActionOption) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            headerView
            optionsList
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 32)
        .background(Color.compound.bgCanvasDefault)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text(prompt)
                .font(.compound.headingSMSemibold)
                .foregroundColor(.compound.textPrimary)
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                CompoundIcon(\.close)
                    .foregroundColor(.compound.iconSecondary)
            }
        }
    }
    
    private var optionsList: some View {
        VStack(spacing: 8) {
            ForEach(options) { option in
                Button {
                    onSelect(option)
                } label: {
                    HStack(spacing: 12) {
                        Text(option.emoji)
                            .font(.system(size: 24))
                        
                        Text(option.label)
                            .font(.compound.bodyLG)
                            .foregroundColor(.compound.textPrimary)
                        
                        Spacer()
                        
                        CompoundIcon(\.chevronRight)
                            .foregroundColor(.compound.iconTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.compound.bgSubtlePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
