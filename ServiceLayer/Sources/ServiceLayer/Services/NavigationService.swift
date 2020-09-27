// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public enum Navigation {
    case url(URL)
    case statusList(StatusListService)
    case accountStatuses(AccountStatusesService)
    case webfingerStart
    case webfingerEnd
}

public struct NavigationService {
    private let status: Status?
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(status: Status?, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.status = status
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
    }
}

public extension NavigationService {
    func item(url: URL) -> AnyPublisher<Navigation, Never> {
        if let tag = tag(url: url) {
            return Just(
                .statusList(
                    StatusListService(
                        timeline: .tag(tag),
                        mastodonAPIClient: mastodonAPIClient,
                        contentDatabase: contentDatabase)))
                .eraseToAnyPublisher()
        } else if let accountID = accountID(url: url) {
            return Just(.accountStatuses(accountStatusesService(id: accountID))).eraseToAnyPublisher()
        } else if mastodonAPIClient.instanceURL.host == url.host, let statusID = url.statusID {
            return Just(
                .statusList(
                    StatusListService(
                        statusID: statusID,
                        mastodonAPIClient: mastodonAPIClient,
                        contentDatabase: contentDatabase)))
                .eraseToAnyPublisher()
        }

        if url.shouldWebfinger {
            return webfinger(url: url)
        } else {
            return Just(.url(url)).eraseToAnyPublisher()
        }
    }

    func contextStatusListService(id: String) -> StatusListService {
        StatusListService(statusID: id, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func accountStatusesService(id: String) -> AccountStatusesService {
        AccountStatusesService(id: id, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func accountStatusesService(account: Account) -> AccountStatusesService {
        AccountStatusesService(account: account, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func statusService(status: Status) -> StatusService {
        StatusService(status: status, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func accountService(account: Account) -> AccountService {
        AccountService(account: account, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }
}

private extension NavigationService {
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

    func webfinger(url: URL) -> AnyPublisher<Navigation, Never> {
        let navigationSubject = PassthroughSubject<Navigation, Never>()

        let request = mastodonAPIClient.request(ResultsEndpoint.search(query: url.absoluteString, resolve: true))
            .handleEvents(
                receiveSubscription: { _ in navigationSubject.send(.webfingerStart) },
                receiveCompletion: { _ in navigationSubject.send(.webfingerEnd) })
            .map { results -> Navigation in
                if let tag = results.hashtags.first {
                    return .statusList(
                        StatusListService(
                            timeline: .tag(tag.name),
                            mastodonAPIClient: mastodonAPIClient,
                            contentDatabase: contentDatabase))
                } else if let account = results.accounts.first {
                    return .accountStatuses(accountStatusesService(account: account))
                } else if let status = results.statuses.first {
                    return .statusList(
                        StatusListService(
                            statusID: status.id,
                            mastodonAPIClient: mastodonAPIClient,
                            contentDatabase: contentDatabase))
                } else {
                    return .url(url)
                }
            }
            .replaceError(with: .url(url))

        return navigationSubject.merge(with: request).eraseToAnyPublisher()
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
