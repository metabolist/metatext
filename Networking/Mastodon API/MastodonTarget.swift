// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct MastodonTarget<E: MastodonEndpoint> {
    let baseURL: URL
    let endpoint: E
    let accessToken: String?
}

extension MastodonTarget: DecodableTarget {
    typealias ResultType = E.ResultType

    var pathComponents: [String] { endpoint.pathComponents }

    var method: HTTPMethod { endpoint.method }

    var encoding: ParameterEncoding { endpoint.encoding }

    var parameters: [String: Any]? { endpoint.parameters }

    var headers: HTTPHeaders? {
        var headers = endpoint.headers

        if let accessToken = accessToken {
            if headers == nil {
                headers = HTTPHeaders()
            }

            headers?.add(.authorization(bearerToken: accessToken))
        }

        return headers
    }
}
