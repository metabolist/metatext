// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class PreferencesViewModel: ObservableObject {
    @Published var preferences: Identity.Preferences

    private let environment: IdentifiedEnvironment

    init(environment: IdentifiedEnvironment) {
        self.environment = environment
        preferences = environment.identity.preferences
        environment.$identity.map(\.preferences).assign(to: &$preferences)
    }
}
