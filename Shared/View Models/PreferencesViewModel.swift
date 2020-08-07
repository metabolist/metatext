// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class PreferencesViewModel: ObservableObject {
    let handle: String

    private let identityRepository: IdentityRepository

    init(identityRepository: IdentityRepository) {
        self.identityRepository = identityRepository
        handle = identityRepository.identity.handle
    }
}

extension PreferencesViewModel {
    func postingReadingPreferencesViewModel() -> PostingReadingPreferencesViewModel {
        PostingReadingPreferencesViewModel(identityRepository: identityRepository)
    }
}
