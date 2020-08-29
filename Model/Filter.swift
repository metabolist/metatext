// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct Filter: Codable, Hashable, Identifiable {
    enum Context: String, Codable, Unknowable {
        case home
        case notifications
        case `public`
        case thread
        case account
        case unknown

        static var unknownCase: Self { .unknown }
    }

    let id: String
    var phrase: String
    var context: [Context]
    var expiresAt: Date?
    var irreversible: Bool
    var wholeWord: Bool
}

extension Filter {
    static let newFilterID: String = "com.metabolist.metatext.new-filter-id"
    static let new = Self(id: newFilterID,
                          phrase: "",
                          context: [],
                          expiresAt: nil,
                          irreversible: false,
                          wholeWord: true)
}

extension Filter.Context: Identifiable {
    var id: Self { self }
}

extension Filter.Context {
    var localized: String {
        switch self {
        case .home:
            return NSLocalizedString("filter.context.home", comment: "")
        case .notifications:
            return NSLocalizedString("filter.context.notifications", comment: "")
        case .public:
            return NSLocalizedString("filter.context.public", comment: "")
        case .thread:
            return NSLocalizedString("filter.context.thread", comment: "")
        case .account:
            return NSLocalizedString("filter.context.account", comment: "")
        case .unknown:
            return NSLocalizedString("filter.context.unknown", comment: "")
        }
    }
}
