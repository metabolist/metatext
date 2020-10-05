// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import ServiceLayer

final public class LoadMoreViewModel: ObservableObject {
    public var direction = LoadMore.Direction.up
    @Published public private(set) var loading = false
    public let events: AnyPublisher<AnyPublisher<CollectionItemEvent, Error>, Never>

    private let loadMoreService: LoadMoreService
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()

    init(loadMoreService: LoadMoreService) {
        self.loadMoreService = loadMoreService
        events = eventsSubject.eraseToAnyPublisher()
    }
}

extension LoadMoreViewModel {
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
