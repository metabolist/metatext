// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP

public struct MastodonAPITarget<E: Endpoint> {
    public let baseURL: URL
    public let endpoint: E
    public let accessToken: String?

    public init(baseURL: URL, endpoint: E, accessToken: String?) {
        self.baseURL = baseURL
        self.endpoint = endpoint
        self.accessToken = accessToken
    }
}

extension MastodonAPITarget: DecodableTarget {
    public typealias ResultType = E.ResultType

    public var pathComponents: [String] { endpoint.pathComponents }

    public var method: HTTPMethod { endpoint.method }

    public var queryParameters: [URLQueryItem] { endpoint.queryParameters }

    public var jsonBody: [String: Any]? { endpoint.jsonBody }

    public var multipartFormData: [String: MultipartFormValue]? { endpoint.multipartFormData }

    public var headers: [String: String]? {
        var headers = endpoint.headers

        if let accessToken = accessToken {
            if headers == nil {
                headers = [String: String]()
            }

            headers?["Authorization"] = "Bearer ".appending(accessToken)
        }

        return headers
    }
}
