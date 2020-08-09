// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class MockUserDefaults: UserDefaults {
    convenience init() {
        self.init(suiteName: Self.suiteName)!
    }

    override init?(suiteName suitename: String?) {
        guard let suitename = suitename else { return nil }

        UserDefaults().removePersistentDomain(forName: suitename)

        super.init(suiteName: suitename)
    }
}

private extension MockUserDefaults {
    private static let suiteName = "com.metatext.metabolist.mock-user-defaults"
}
