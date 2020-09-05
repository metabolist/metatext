// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import HTTP
import Mastodon

public final class MastodonAPIClient: Client {
    public var instanceURL: URL?
    public var accessToken: String?

    public required init(session: Session) {
        super.init(session: session, decoder: MastodonDecoder())
    }

    public override func request<T: DecodableTarget>(_ target: T) -> AnyPublisher<T.ResultType, Error> {
        super.request(target, decodeErrorsAs: APIError.self)
    }
}

extension MastodonAPIClient {
    public func request<E: Endpoint>(_ endpoint: E) -> AnyPublisher<E.ResultType, Error> {
        guard let instanceURL = instanceURL else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return super.request(
            MastodonAPITarget(baseURL: instanceURL, endpoint: endpoint, accessToken: accessToken),
            decodeErrorsAs: APIError.self)
    }
}
