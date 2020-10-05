// Copyright © 2020 Metabolist. All rights reserved.

import Combine

public protocol CollectionService {
    var sections: AnyPublisher<[[CollectionItem]], Error> { get }
    var nextPageMaxIDs: AnyPublisher<String, Never> { get }
    var title: AnyPublisher<String, Never> { get }
    var navigationService: NavigationService { get }
    var contextParentID: String? { get }
    func request(maxID: String?, minID: String?) -> AnyPublisher<Never, Error>
}

extension CollectionService {
    public var nextPageMaxIDs: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    public var title: AnyPublisher<String, Never> { Empty().eraseToAnyPublisher() }

    public var contextParentID: String? { nil }
}
