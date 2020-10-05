// Copyright © 2020 Metabolist. All rights reserved.

import Combine

public protocol CollectionService {
    var sections: AnyPublisher<[[CollectionItem]], Error> { get }
    var nextPageMaxId: AnyPublisher<String, Never> { get }
    var title: AnyPublisher<String, Never> { get }
    var navigationService: NavigationService { get }
    var contextParentId: String? { get }
    func request(maxId: String?, minId: String?) -> AnyPublisher<Never, Error>
}

extension CollectionService {
    public var nextPageMaxId: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    public var title: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    public var contextParentId: String? { nil }
}
