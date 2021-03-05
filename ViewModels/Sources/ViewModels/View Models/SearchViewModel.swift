// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class SearchViewModel: CollectionItemsViewModel {
    @Published public var query = ""
    @Published public var scope = SearchScope.all

    private let searchService: SearchService
    private var cancellables = Set<AnyCancellable>()

    public init(identityContext: IdentityContext) {
        self.searchService = identityContext.service.searchService()

        super.init(collectionService: searchService, identityContext: identityContext)

        $query.dropFirst()
            .debounce(for: .seconds(Self.debounceInterval), scheduler: DispatchQueue.global())
            .removeDuplicates()
            .combineLatest($scope.removeDuplicates())
            .sink { [weak self] in
                self?.cancelRequests()
                self?.request(
                    maxId: nil,
                    minId: nil,
                    search: .init(query: $0, type: $1.type, limit: $1.limit))
            }
            .store(in: &cancellables)
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
    static let debounceInterval: TimeInterval = 0.2
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
