// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import HTTP
import Mastodon

public final class MastodonAPIClient: HTTPClient {
    public var instanceURL: URL
    public var accessToken: String?

    public required init(session: URLSession, instanceURL: URL) {
        self.instanceURL = instanceURL
        super.init(session: session, decoder: MastodonDecoder())
    }

    public override func request<T: DecodableTarget>(_ target: T) -> AnyPublisher<T.ResultType, Error> {
        super.request(target, decodeErrorsAs: APIError.self)
    }
}

extension MastodonAPIClient {
    public func request<E: Endpoint>(_ endpoint: E) -> AnyPublisher<E.ResultType, Error> {
        super.request(
            MastodonAPITarget(baseURL: instanceURL, endpoint: endpoint, accessToken: accessToken),
            decodeErrorsAs: APIError.self)
    }
}
