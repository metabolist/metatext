// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import ServiceLayer

public struct LoadMoreViewModel {
    public let loading: AnyPublisher<Bool, Never>
    public let events: AnyPublisher<AnyPublisher<CollectionItemEvent, Error>, Never>

    private let loadMoreService: LoadMoreService
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()
    private let loadingSubject = PassthroughSubject<Bool, Never>()

    init(loadMoreService: LoadMoreService) {
        self.loadMoreService = loadMoreService
        loading = loadingSubject.eraseToAnyPublisher()
        events = eventsSubject.eraseToAnyPublisher()
    }
}

extension LoadMoreViewModel {
    func loadMore() {
        eventsSubject.send(
            loadMoreService.request(direction: .down)
                .handleEvents(
                    receiveSubscription: { _ in loadingSubject.send(true) },
                    receiveCompletion: { _ in loadingSubject.send(false) })
                .map { _ in CollectionItemEvent.ignorableOutput }
                .eraseToAnyPublisher())
    }
}
