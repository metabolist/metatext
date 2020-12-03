// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Filter: Codable, Hashable, Identifiable {
    public enum Context: String, Codable, Unknowable {
        case home
        case notifications
        case `public`
        case thread
        case account
        case unknown

        public static var unknownCase: Self { .unknown }
    }

    public let id: Id
    public var phrase: String
    public var context: [Context]
    public var expiresAt: Date?
    public var irreversible: Bool
    public var wholeWord: Bool
}

public extension Filter {
    typealias Id = String

    static let newFilterId: Id = "com.metabolist.metatext.new-filter-id"
    static let new = Self(id: newFilterId,
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
    public func regularExpression(context: Filter.Context?) -> String? {
        guard let context = context else { return nil }

        let inContext = filter { $0.context.contains(context) }

        guard !inContext.isEmpty else { return nil }

        return inContext.map {
            var expression = NSRegularExpression.escapedPattern(for: $0.phrase)

            if $0.wholeWord {
                if expression.range(of: #"^[\w]"#, options: .regularExpression) != nil {
                    expression = #"\b"#.appending(expression)
                }

                if expression.range(of: #"[\w]$"#, options: .regularExpression) != nil {
                    expression.append(#"\b"#)
                }
            }

            return expression
        }
        .joined(separator: "|")
    }
}

extension Filter.Context: Identifiable {
    public var id: Self { self }
}
