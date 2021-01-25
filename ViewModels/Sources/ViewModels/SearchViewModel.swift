// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class SearchViewModel: CollectionItemsViewModel {
    @Published public var query = ""
    @Published public var scope = SearchScope.all

    private let searchService: SearchService
    private var cancellables = Set<AnyCancellable>()

    public init(searchService: SearchService, identification: Identification) {
        self.searchService = searchService

        super.init(collectionService: searchService, identification: identification)

        $query.removeDuplicates()
            .throttle(for: .seconds(Self.throttleInterval), scheduler: DispatchQueue.global(), latest: true)
            .combineLatest($scope.removeDuplicates())
            .sink { [weak self] in
                self?.request(
                    maxId: nil,
                    minId: nil,
                    search: .init(query: $0, type: $1.type, limit: $1.limit))
            }
            .store(in: &cancellables)
    }

    public override var updates: AnyPublisher<CollectionUpdate, Never> {
        // Since results are processed through the DB to determine CW expansion state etc they can arrive erratically
        super.updates
            .throttle(for: .seconds(Self.throttleInterval), scheduler: DispatchQueue.global(), latest: true)
            .eraseToAnyPublisher()
    }

    public override func requestNextPage(fromIndexPath indexPath: IndexPath) {
        guard scope != .all else { return }

        request(
            maxId: nil,
            minId: nil,
            search: .init(query: query, type: scope.type, offset: indexPath.item + 1))
    }
}

private extension SearchViewModel {
    static let throttleInterval: TimeInterval = 0.5
}

private extension SearchScope {
    var type: Search.SearchType? {
        switch self {
        case .all:
            return nil
        case .accounts:
            return .accounts
        case .statuses:
            return .statuses
        case .tags:
            return .hashtags
        }
    }

    var limit: Int? {
        switch self {
        case .all:
            return 5
        default:
            return nil
        }
    }
}
