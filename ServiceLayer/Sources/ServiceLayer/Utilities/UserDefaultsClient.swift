// Copyright © 2020 Metabolist. All rights reserved.

import CodableBloomFilter
import Foundation

class UserDefaultsClient {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
}

extension UserDefaultsClient {
    var updatedInstanceFilter: BloomFilter<String>? {
        get {
            guard let data = self[.updatedFilter] as Data? else {
                return nil
            }

            return try? JSONDecoder().decode(BloomFilter<String>.self, from: data)
        }

        set {
            var data: Data?

            if let newValue = newValue {
                data = try? JSONEncoder().encode(newValue)
            }

            self[.updatedFilter] = data
        }
    }
}

private extension UserDefaultsClient {
    enum Item: String {
        case updatedFilter
    }

    subscript<T>(index: Item) -> T? {
        get { userDefaults.value(forKey: index.rawValue) as? T }
        set { userDefaults.set(newValue, forKey: index.rawValue) }
    }
}
