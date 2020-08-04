// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class SettingsViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    private let environment: AppEnvironment

    init(identity: Published<Identity>, environment: AppEnvironment) {
        _identity = identity
        self.environment = environment
    }
}

extension SettingsViewModel {
    func identitiesViewModel() -> IdentitiesViewModel {
        IdentitiesViewModel(identity: _identity, environment: environment)
    }
}
