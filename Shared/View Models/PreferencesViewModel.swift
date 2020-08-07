// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class PreferencesViewModel: ObservableObject {
    let handle: String

    private let environment: IdentifiedEnvironment

    init(environment: IdentifiedEnvironment) {
        self.environment = environment
        handle = environment.identity.handle
    }
}

extension PreferencesViewModel {
    func postingReadingPreferencesViewModel() -> PostingReadingPreferencesViewModel {
        PostingReadingPreferencesViewModel(environment: environment)
    }
}
