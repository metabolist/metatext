// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public enum Navigation {
    case url(URL)
    case collection(CollectionService)
    case profile(ProfileService)
    case webfingerStart
    case webfingerEnd
}

public struct NavigationService {
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let status: Status?

    init(mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase, status: Status? = nil) {
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
        self.status = status
    }
}

public extension NavigationService {
    func item(url: URL) -> AnyPublisher<Navigation, Never> {
        if let tag = tag(url: url) {
            return Just(
                .collection(
                    TimelineService(
                        timeline: .tag(tag),
                        mastodonAPIClient: mastodonAPIClient,
                        contentDatabase: contentDatabase)))
                .eraseToAnyPublisher()
        } else if let accountId = accountId(url: url) {
            return Just(.profile(profileService(id: accountId))).eraseToAnyPublisher()
        } else if mastodonAPIClient.instanceURL.host == url.host, let statusId = url.statusId {
            return Just(.collection(contextService(id: statusId))).eraseToAnyPublisher()
        }

        if url.shouldWebfinger {
            return webfinger(url: url)
        } else {
            return Just(.url(url)).eraseToAnyPublisher()
        }
    }

    func contextService(id: Status.Id) -> ContextService {
        ContextService(id: id, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func profileService(id: Account.Id) -> ProfileService {
        ProfileService(id: id, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func profileService(account: Account) -> ProfileService {
        ProfileService(account: account, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func statusService(status: Status) -> StatusService {
        StatusService(status: status, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func accountService(account: Account) -> AccountService {
        AccountService(account: account, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
    }

    func loadMoreService(loadMore: LoadMore) -> LoadMoreService {
        LoadMoreService(loadMore: loadMore, mastodonAPIClient: mastodonAPIClient, contentDatabase: contentDatabase)
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

    func accountId(url: URL) -> String? {
        if let mentionId = status?.mentions.first(where: { $0.url.path.lowercased() == url.path.lowercased() })?.id {
            return mentionId
        } else if
            mastodonAPIClient.instanceURL.host == url.host {
            return url.accountId
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
                    return .collection(
                        TimelineService(
                            timeline: .tag(tag.name),
                            mastodonAPIClient: mastodonAPIClient,
                            contentDatabase: contentDatabase))
                } else if let account = results.accounts.first {
                    return .profile(profileService(account: account))
                } else if let status = results.statuses.first {
                    return .collection(contextService(id: status.id))
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

    var accountId: Account.Id? {
        if let accountId = pathComponents.last, pathComponents == ["/", "web", "accounts", accountId] {
            return accountId
        }

        return nil
    }

    var statusId: Status.Id? {
        guard let statusId = pathComponents.last else { return nil }

        if pathComponents.count == 3, pathComponents[1].starts(with: "@") {
            return statusId
        } else if pathComponents == ["/", "web", "statuses", statusId] {
            return statusId
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
        isAccountURL || accountId != nil || statusId != nil || tag != nil
    }
}
