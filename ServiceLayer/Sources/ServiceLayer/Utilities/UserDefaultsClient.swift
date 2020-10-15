// Copyright © 2020 Metabolist. All rights reserved.

import CodableBloomFilter
import Foundation

struct UserDefaultsClient {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
}

extension UserDefaultsClient {
    var updatedInstanceFilter: BloomFilter<String>? {
        guard let data = self[.updatedFilter] as Data? else {
            return nil
        }

        return try? JSONDecoder().decode(BloomFilter<String>.self, from: data)
    }

    func updateInstanceFilter( _ filter: BloomFilter<String>) {
        userDefaults.set(try? JSONEncoder().encode(filter), forKey: Item.updatedFilter.rawValue)
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
