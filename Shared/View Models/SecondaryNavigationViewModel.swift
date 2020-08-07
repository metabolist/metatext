// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class SecondaryNavigationViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    private let environment: IdentifiedEnvironment

    init(environment: IdentifiedEnvironment) {
        self.environment = environment
        identity = environment.identity
        environment.$identity.dropFirst().assign(to: &$identity)
    }
}

extension SecondaryNavigationViewModel {
    func identitiesViewModel() -> IdentitiesViewModel {
        IdentitiesViewModel(environment: environment)
    }
}
