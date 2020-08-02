// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

class FakeUserDefaults: UserDefaults {
    convenience init() {
        self.init(suiteName: Self.suiteName)!
    }

    override init?(suiteName suitename: String?) {
        guard let suitename = suitename else { return nil }

        UserDefaults().removePersistentDomain(forName: suitename)

        super.init(suiteName: suitename)
    }
}

private extension FakeUserDefaults {
    private static let suiteName = "com.metatext.metabolist.fake-user-defaults"
}
