// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class SettingsViewModel: ObservableObject {
    private let identity: CurrentValuePublisher<Identity>
    private let environment: AppEnvironment

    init(identity: CurrentValuePublisher<Identity>, environment: AppEnvironment) {
        self.identity = identity
        self.environment = environment
    }
}
