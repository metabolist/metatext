// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class Preferences {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
}

extension Preferences {
    enum Item: String {
        case recentIdentityID = "recent-identity-id"
    }
}

extension Preferences {
    subscript<T>(index: Preferences.Item) -> T? {
        get { userDefaults.value(forKey: index.rawValue) as? T }
        set { userDefaults.set(newValue, forKey: index.rawValue) }
    }
}
