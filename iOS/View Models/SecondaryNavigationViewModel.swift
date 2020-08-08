// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class SecondaryNavigationViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    private let identityRepository: IdentityRepository

    init(identityRepository: IdentityRepository) {
        self.identityRepository = identityRepository
        identity = identityRepository.identity
        identityRepository.$identity.dropFirst().assign(to: &$identity)
    }
}

extension SecondaryNavigationViewModel {
    func identitiesViewModel() -> IdentitiesViewModel {
        IdentitiesViewModel(identityRepository: identityRepository)
    }

    func preferencesViewModel() -> PreferencesViewModel {
        PreferencesViewModel(identityRepository: identityRepository)
    }
}
