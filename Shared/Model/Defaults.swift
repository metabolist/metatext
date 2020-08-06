// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class Defaults {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
}

extension Defaults {
    enum Item: String {
        case recentIdentityID = "recent-identity-id"
    }
}

extension Defaults {
    subscript<T>(index: Defaults.Item) -> T? {
        get { userDefaults.value(forKey: index.rawValue) as? T }
        set { userDefaults.set(newValue, forKey: index.rawValue) }
    }
}
