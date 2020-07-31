// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class SettingsViewModel: ObservableObject {
    let identity: Identity

    init(identity: Identity) {
        self.identity = identity
    }
}
