// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Mastodon

public protocol CollectionService {
    var sections: AnyPublisher<[CollectionSection], Error> { get }
    var nextPageMaxId: AnyPublisher<String, Never> { get }
    var accountIdsForRelationships: AnyPublisher<Set<Account.Id>, Never> { get }
    var preferLastPresentIdOverNextPageMaxId: Bool { get }
    var canRefresh: Bool { get }
    var title: AnyPublisher<String, Never> { get }
    var titleLocalizationComponents: AnyPublisher<[String], Never> { get }
    var announcesNewItems: Bool { get }
    var navigationService: NavigationService { get }
    var positionTimeline: Timeline? { get }
    func request(maxId: String?, minId: String?, search: Search?) -> AnyPublisher<Never, Error>
    func requestMarkerLastReadId() -> AnyPublisher<CollectionItem.Id, Error>
    func setMarkerLastReadId(_ id: CollectionItem.Id) -> AnyPublisher<CollectionItem.Id, Error>
}

extension CollectionService {
    public var nextPageMaxId: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    public var accountIdsForRelationships: AnyPublisher<Set<Account.Id>, Never> { Empty().eraseToAnyPublisher() }

    public var preferLastPresentIdOverNextPageMaxId: Bool { false }

    public var canRefresh: Bool { true }

    public var title: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    public var titleLocalizationComponents: AnyPublisher<[String], Never> { Empty().eraseToAnyPublisher() }

    public var announcesNewItems: Bool { false }

    public var positionTimeline: Timeline? { nil }

    public func requestMarkerLastReadId() -> AnyPublisher<CollectionItem.Id, Error> { Empty().eraseToAnyPublisher() }

    public func setMarkerLastReadId(_ id: CollectionItem.Id) -> AnyPublisher<CollectionItem.Id, Error> {
        Empty().eraseToAnyPublisher()
    }
}
