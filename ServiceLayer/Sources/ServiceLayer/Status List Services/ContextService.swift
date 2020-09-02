// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine
import Mastodon

public struct ContextService {
    public let statusSections: AnyPublisher<[[Status]], Error>
    public let paginates = false

    private let status: Status
    private let context = CurrentValueSubject<Context, Never>(Context(ancestors: [], descendants: []))
    private let networkClient: APIClient
    private let contentDatabase: ContentDatabase

    init(status: Status, networkClient: APIClient, contentDatabase: ContentDatabase) {
        self.status = status
        self.networkClient = networkClient
        self.contentDatabase = contentDatabase
        statusSections = contentDatabase.contextObservation(parentID: status.id)
    }
}

extension ContextService: StatusListService {
    public var filters: AnyPublisher<[Filter], Error> {
        contentDatabase.activeFiltersObservation(date: Date(), context: .thread)
    }

    public var contextParentID: String? { status.id }

    public func isReplyInContext(status: Status) -> Bool {
        let flatContext = flattenedContext()

        guard
            let index = flatContext.firstIndex(where: { $0.id == status.id }),
            index > 0
        else { return false }

        let previousStatus = flatContext[index - 1]

        return previousStatus.id != contextParentID && status.inReplyToId == previousStatus.id
    }

    public func hasReplyFollowing(status: Status) -> Bool {
        let flatContext = flattenedContext()

        guard
            let index = flatContext.firstIndex(where: { $0.id == status.id }),
            flatContext.count > index + 1
        else { return false }

        let nextStatus = flatContext[index + 1]

        return status.id != contextParentID && nextStatus.inReplyToId == status.id
    }

    public func request(maxID: String?, minID: String?) -> AnyPublisher<Never, Error> {
        Publishers.Merge(
            networkClient.request(StatusEndpoint.status(id: status.id))
                .map { ([$0], nil) }
                .flatMap(contentDatabase.insert(statuses:timeline:))
                .eraseToAnyPublisher(),
            networkClient.request(ContextEndpoint.context(id: status.id))
                .handleEvents(receiveOutput: context.send)
                .map { ($0, status.id) }
                .flatMap(contentDatabase.insert(context:parentID:))
                .eraseToAnyPublisher())
            .eraseToAnyPublisher()
    }

    public func statusService(status: Status) -> StatusService {
        StatusService(status: status, networkClient: networkClient, contentDatabase: contentDatabase)
    }

    public func contextService(status: Status) -> ContextService {
        ContextService(status: status.displayStatus, networkClient: networkClient, contentDatabase: contentDatabase)
    }
}

private extension ContextService {
    func flattenedContext() -> [Status] {
        context.value.ancestors + [status] + context.value.descendants
    }
}
