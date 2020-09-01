// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import ServiceLayer

public class SecondaryNavigationViewModel: ObservableObject {
    @Published public private(set) var identity: Identity

    private let identityService: IdentityService

    init(identityService: IdentityService) {
        self.identityService = identityService
        identity = identityService.identity
        identityService.$identity.dropFirst().assign(to: &$identity)
    }
}

public extension SecondaryNavigationViewModel {
    func identitiesViewModel() -> IdentitiesViewModel {
        IdentitiesViewModel(identityService: identityService)
    }

    func listsViewModel() -> ListsViewModel {
        ListsViewModel(identityService: identityService)
    }

    func preferencesViewModel() -> PreferencesViewModel {
        PreferencesViewModel(identityService: identityService)
    }
}
