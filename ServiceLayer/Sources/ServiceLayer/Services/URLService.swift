// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public enum URLItem {
    case url(URL)
    case statusID(String)
    case accountID(String)
    case tag(String)
}

public struct URLService {
    private let status: Status?
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(status: Status?, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.status = status
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
    }
}

public extension URLService {
    func item(url: URL) -> AnyPublisher<URLItem, Never> {
        if let tag = tag(url: url) {
            return Just(.tag(tag)).eraseToAnyPublisher()
        } else if let accountID = accountID(url: url) {
            return Just(.accountID(accountID)).eraseToAnyPublisher()
        } else if mastodonAPIClient.instanceURL.host == url.host, let statusID = url.statusID {
            return Just(.statusID(statusID)).eraseToAnyPublisher()
        }

        return Just(.url(url)).eraseToAnyPublisher()
    }
}

private extension URLService {
    func tag(url: URL) -> String? {
        if status?.tags.first(where: { $0.url.path.lowercased() == url.path.lowercased() }) != nil {
            return url.lastPathComponent
        } else if
            mastodonAPIClient.instanceURL.host == url.host {
            return url.tag
        }

        return nil
    }

    func accountID(url: URL) -> String? {
        if let mentionID = status?.mentions.first(where: { $0.url.path.lowercased() == url.path.lowercased() })?.id {
            return mentionID
        } else if
            mastodonAPIClient.instanceURL.host == url.host {
            return url.accountID
        }

        return nil
    }
}

private extension URL {
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
