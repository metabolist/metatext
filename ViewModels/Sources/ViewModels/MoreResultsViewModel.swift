// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import ServiceLayer

public final class MoreResultsViewModel: ObservableObject, CollectionItemViewModel {
    public var events: AnyPublisher<AnyPublisher<CollectionItemEvent, Error>, Never>

    private let moreResults: MoreResults
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()

    init(moreResults: MoreResults) {
        self.moreResults = moreResults
        events = eventsSubject.eraseToAnyPublisher()
    }
}

public extension MoreResultsViewModel {
    var scope: SearchScope { moreResults.scope }
}
