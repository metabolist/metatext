// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

struct ContextService {
    let statusSections: AnyPublisher<[[Status]], Error>

    private var status: Status
    private let context = CurrentValueSubject<MastodonContext, Never>(MastodonContext(ancestors: [], descendants: []))
    private let networkClient: MastodonClient
    private let contentDatabase: ContentDatabase
    private let collection: TransientStatusCollection

    init(status: Status, networkClient: MastodonClient, contentDatabase: ContentDatabase) {
        self.status = status
        self.networkClient = networkClient
        self.contentDatabase = contentDatabase
        collection = TransientStatusCollection(id: "context-\(status.id)")
        statusSections = contentDatabase.statusesObservation(collection: collection)
            .combineLatest(context.setFailureType(to: Error.self))
            .map { statuses, context in
                [
                    context.ancestors.map { a in statuses.first { $0.id == a.id } ?? a },
                    [statuses.first { $0.id == status.id } ?? status],
                    context.descendants.map { d in statuses.first { $0.id == d.id } ?? d }
                ]
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

extension ContextService: StatusListService {
    var contextParent: Status? { status }

    func request(maxID: String?, minID: String?) -> AnyPublisher<Void, Error> {
        networkClient.request(ContextEndpoint.context(id: status.id))
            .handleEvents(receiveOutput: context.send)
            .map { ($0.ancestors + $0.descendants, collection) }
            .flatMap(contentDatabase.insert(statuses:collection:))
            .eraseToAnyPublisher()
    }

    func contextService(status: Status) -> ContextService {
        ContextService(status: status, networkClient: networkClient, contentDatabase: contentDatabase)
    }
}
