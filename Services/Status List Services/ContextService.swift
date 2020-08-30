// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import Mastodon

struct ContextService {
    let statusSections: AnyPublisher<[[Status]], Error>
    let paginates = false

    private let status: Status
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
    var filters: AnyPublisher<[Filter], Error> {
        contentDatabase.activeFiltersObservation(date: Date(), context: .thread)
    }

    var contextParentID: String? { status.id }

    func isReplyInContext(status: Status) -> Bool {
        let flatContext = flattenedContext()

        guard
            let index = flatContext.firstIndex(where: { $0.id == status.id }),
            index > 0
        else { return false }

        let previousStatus = flatContext[index - 1]

        return previousStatus.id != contextParentID && status.inReplyToId == previousStatus.id
    }

    func hasReplyFollowing(status: Status) -> Bool {
        let flatContext = flattenedContext()

        guard
            let index = flatContext.firstIndex(where: { $0.id == status.id }),
            flatContext.count > index + 1
        else { return false }

        let nextStatus = flatContext[index + 1]

        return status.id != contextParentID && nextStatus.inReplyToId == status.id
    }

    func request(maxID: String?, minID: String?) -> AnyPublisher<Never, Error> {
        Publishers.Merge(
            networkClient.request(StatusEndpoint.status(id: status.id))
                .map { ([$0], collection) }
                .flatMap(contentDatabase.insert(statuses:collection:)),
            networkClient.request(ContextEndpoint.context(id: status.id))
                .handleEvents(receiveOutput: context.send)
                .map { ($0.ancestors + $0.descendants, collection) }
                .flatMap(contentDatabase.insert(statuses:collection:)))
            .eraseToAnyPublisher()
    }

    func statusService(status: Status) -> StatusService {
        StatusService(status: status, networkClient: networkClient, contentDatabase: contentDatabase)
    }

    func contextService(status: Status) -> ContextService {
        ContextService(status: status.displayStatus, networkClient: networkClient, contentDatabase: contentDatabase)
    }
}

private extension ContextService {
    func flattenedContext() -> [Status] {
        context.value.ancestors + [status] + context.value.descendants
    }
}
