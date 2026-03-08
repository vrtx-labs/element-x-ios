//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct VoiceAgentSettingsScreenCoordinatorParameters {
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let roomProxy: JoinedRoomProxyProtocol
}

final class VoiceAgentSettingsScreenCoordinator: CoordinatorProtocol {
    private let parameters: VoiceAgentSettingsScreenCoordinatorParameters
    private var viewModel: VoiceAgentSettingsScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(parameters: VoiceAgentSettingsScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = VoiceAgentSettingsScreenViewModel(roomProxy: parameters.roomProxy)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            switch action {
            case .dismiss:
                self?.parameters.navigationStackCoordinator?.pop(animated: true)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(VoiceAgentSettingsScreen(context: viewModel.context))
    }
}
