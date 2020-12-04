// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct DomainBlocksService {
    public let nextPageMaxId: AnyPublisher<String, Never>

    private let mastodonAPIClient: MastodonAPIClient
    private let nextPageMaxIdSubject = PassthroughSubject<String, Never>()

    public init(mastodonAPIClient: MastodonAPIClient) {
        self.mastodonAPIClient = mastodonAPIClient
        nextPageMaxId = nextPageMaxIdSubject.eraseToAnyPublisher()
    }
}

public extension DomainBlocksService {
    func request(maxId: String?) -> AnyPublisher<[String], Error> {
        mastodonAPIClient.pagedRequest(StringsEndpoint.domainBlocks, maxId: maxId)
            .handleEvents(receiveOutput: {
                if let maxId = $0.info.maxId {
                    nextPageMaxIdSubject.send(maxId)
                }
            })
            .map(\.result)
            .eraseToAnyPublisher()
    }

    func delete(domain: String) -> AnyPublisher<Never, Error> {
        mastodonAPIClient.request(EmptyEndpoint.unblockDomain(domain)).ignoreOutput().eraseToAnyPublisher()
    }
}
