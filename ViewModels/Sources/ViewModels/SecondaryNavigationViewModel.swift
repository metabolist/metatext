// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import ServiceLayer

public class SecondaryNavigationViewModel: ObservableObject {
    @Published public private(set) var identity: Identity

    private let environment: IdentifiedEnvironment

    init(environment: IdentifiedEnvironment) {
        self.environment = environment
        identity = environment.identity
        environment.$identity.dropFirst().assign(to: &$identity)
    }
}

public extension SecondaryNavigationViewModel {
    func identitiesViewModel() -> IdentitiesViewModel {
        IdentitiesViewModel(environment: environment)
    }

    func listsViewModel() -> ListsViewModel {
        ListsViewModel(environment: environment)
    }

    func preferencesViewModel() -> PreferencesViewModel {
        PreferencesViewModel(environment: environment)
    }
}
