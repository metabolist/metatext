// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class SearchViewModel: CollectionItemsViewModel {
    @Published public var query = ""

    private let searchService: SearchService
    private var cancellables = Set<AnyCancellable>()

    public init(searchService: SearchService, identification: Identification) {
        self.searchService = searchService

        super.init(collectionService: searchService, identification: identification)

        $query.throttle(for: .seconds(Self.queryThrottleInterval), scheduler: DispatchQueue.global(), latest: true)
            .sink { [weak self] in self?.request(maxId: nil, minId: nil, search: .init(query: $0, limit: Self.limit)) }
            .store(in: &cancellables)
    }
}

private extension SearchViewModel {
    static let queryThrottleInterval: TimeInterval = 0.5
    static let limit = 5
}
