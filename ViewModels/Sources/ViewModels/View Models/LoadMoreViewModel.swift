// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import ServiceLayer

public final class LoadMoreViewModel: ObservableObject {
    public var direction = LoadMore.Direction.up
    @Published public private(set) var loading = false
    public let identityContext: IdentityContext

    private let loadMoreService: LoadMoreService
    private let eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>

    init(loadMoreService: LoadMoreService,
         eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>,
         identityContext: IdentityContext) {
        self.loadMoreService = loadMoreService
        self.eventsSubject = eventsSubject
        self.identityContext = identityContext
    }
}

public extension LoadMoreViewModel {
    func loadMore() {
        eventsSubject.send(
            loadMoreService.request(direction: direction)
                .handleEvents(
                    receiveSubscription: { [weak self] _ in self?.loading = true },
                    receiveCompletion: { [weak self] _ in self?.loading = false })
                .map { _ in CollectionItemEvent.ignorableOutput }
                .eraseToAnyPublisher())
    }
}
