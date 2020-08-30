// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

public class MastodonClient: HTTPClient {
    public var instanceURL: URL?
    public var accessToken: String?

    public required init(session: Session) {
        super.init(session: session, decoder: MastodonDecoder())
    }

    public override func request<T: DecodableTarget>(_ target: T) -> AnyPublisher<T.ResultType, Error> {
        super.request(target, decodeErrorsAs: MastodonError.self)
    }
}

extension MastodonClient {
    public func request<E: MastodonEndpoint>(_ endpoint: E) -> AnyPublisher<E.ResultType, Error> {
        guard let instanceURL = instanceURL else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return super.request(
            MastodonTarget(baseURL: instanceURL, endpoint: endpoint, accessToken: accessToken),
            decodeErrorsAs: MastodonError.self)
    }
}
