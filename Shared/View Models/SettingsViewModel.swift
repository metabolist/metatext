// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class SettingsViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    private let environment: IdentifiedEnvironment

    init(environment: IdentifiedEnvironment) {
        self.environment = environment
        identity = environment.identity
        environment.$identity.dropFirst().assign(to: &$identity)
    }
}

extension SettingsViewModel {
    func identitiesViewModel() -> IdentitiesViewModel {
        IdentitiesViewModel(environment: environment)
    }
}
