// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Mastodon

public protocol CollectionService {
    var sections: AnyPublisher<[[CollectionItem]], Error> { get }
    var nextPageMaxId: AnyPublisher<String, Never> { get }
    var preferLastPresentIdOverNextPageMaxId: Bool { get }
    var canRefresh: Bool { get }
    var title: AnyPublisher<String, Never> { get }
    var titleLocalizationComponents: AnyPublisher<[String], Never> { get }
    var navigationService: NavigationService { get }
    var markerTimeline: Marker.Timeline? { get }
    func request(maxId: String?, minId: String?, search: Search?) -> AnyPublisher<Never, Error>
}

extension CollectionService {
    public var nextPageMaxId: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    public var preferLastPresentIdOverNextPageMaxId: Bool { false }

    public var canRefresh: Bool { true }

    public var title: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    public var titleLocalizationComponents: AnyPublisher<[String], Never> { Empty().eraseToAnyPublisher() }

    public var markerTimeline: Marker.Timeline? { nil }
}
