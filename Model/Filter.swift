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

extension Array where Element == Filter {
    // swiftlint:disable line_length
    // Adapted from https://github.com/tootsuite/mastodon/blob/bf477cee9f31036ebf3d164ddec1cebef5375513/app/javascript/mastodon/selectors/index.js#L43
    // swiftlint:enable line_length
    func regularExpression() -> String? {
        guard !isEmpty else { return nil }

        return map {
            var expression = NSRegularExpression.escapedPattern(for: $0.phrase)

            if $0.wholeWord {
                if expression.range(of: #"^[\w]"#, options: .regularExpression) != nil {
                    expression = #"\b"# + expression
                }

                if expression.range(of: #"[\w]$"#, options: .regularExpression) != nil {
                    expression += #"\b"#
                }
            }

            return expression
        }
        .joined(separator: "|")
    }
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
