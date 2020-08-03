// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class MastodonClient: HTTPClient {
    var instanceURL: URL?
    var accessToken: String?

    init(configuration: URLSessionConfiguration = URLSessionConfiguration.af.default) {
        super.init(configuration: configuration, decoder: MastodonDecoder())
    }

    override func request<T: DecodableTarget>(_ target: T) -> AnyPublisher<T.ResultType, Error> {
        super.request(target, decodeErrorsAs: MastodonError.self)
    }
}

extension MastodonClient {
    func request<E: MastodonEndpoint>(_ endpoint: E) -> AnyPublisher<E.ResultType, Error> {
        guard let instanceURL = instanceURL else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return super.request(
            MastodonTarget(baseURL: instanceURL, endpoint: endpoint, accessToken: accessToken),
            decodeErrorsAs: MastodonError.self)
    }
}
