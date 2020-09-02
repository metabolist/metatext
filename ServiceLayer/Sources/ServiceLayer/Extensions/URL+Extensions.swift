// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension URL {
    var isAccountURL: Bool {
        (pathComponents.count == 2 && pathComponents[1].starts(with: "@"))
            || (pathComponents.count == 3 && pathComponents[0...1] == ["/", "users"])
    }

    var accountID: String? {
        if let accountID = pathComponents.last, pathComponents == ["/", "web", "accounts", accountID] {
            return accountID
        }

        return nil
    }

    var statusID: String? {
        guard let statusID = pathComponents.last else { return nil }

        if pathComponents.count == 3, pathComponents[1].starts(with: "@") {
            return statusID
        } else if pathComponents == ["/", "web", "statuses", statusID] {
            return statusID
        }

        return nil
    }

    var tag: String? {
        if let tag = pathComponents.last, pathComponents == ["/", "tags", tag] {
            return tag
        }

        return nil
    }

    var shouldWebfinger: Bool {
        isAccountURL || accountID != nil || statusID != nil || tag != nil
    }
}
