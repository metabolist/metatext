// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP

public struct APITarget<E: Endpoint> {
    public let baseURL: URL
    public let endpoint: E
    public let accessToken: String?

    public init(baseURL: URL, endpoint: E, accessToken: String?) {
        self.baseURL = baseURL
        self.endpoint = endpoint
        self.accessToken = accessToken
    }
}

extension APITarget: DecodableTarget {
    public typealias ResultType = E.ResultType

    public var pathComponents: [String] { endpoint.pathComponents }

    public var method: HTTPMethod { endpoint.method }

    public var encoding: ParameterEncoding { endpoint.encoding }

    public var parameters: [String: Any]? { endpoint.parameters }

    public var headers: HTTPHeaders? {
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
