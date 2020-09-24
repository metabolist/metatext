// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public struct Paged<T: Endpoint> {
    public let endpoint: T
    public let maxID: String?
    public let minID: String?
    public let sinceID: String?
    public let limit: Int?

    public init(_ endpoint: T, maxID: String? = nil, minID: String? = nil, sinceID: String? = nil, limit: Int? = nil) {
        self.endpoint = endpoint
        self.maxID = maxID
        self.minID = minID
        self.sinceID = sinceID
        self.limit = limit
    }
}

extension Paged: Endpoint {
    public typealias ResultType = PagedResult<T.ResultType>

    public var APIVersion: String { endpoint.APIVersion }

    public var context: [String] { endpoint.context }

    public var pathComponentsInContext: [String] { endpoint.pathComponentsInContext }

    public var method: HTTPMethod { endpoint.method }

    public var queryParameters: [String: String]? {
        var queryParameters = endpoint.queryParameters ?? [String: String]()

        queryParameters["max_id"] = maxID
        queryParameters["min_id"] = minID
        queryParameters["since_id"] = sinceID

        if let limit = limit {
            queryParameters["limit"] = String(limit)
        }

        return queryParameters
    }

    public var headers: [String: String]? { endpoint.headers }
}

public struct PagedResult<T: Decodable>: Decodable {
    public struct Info: Decodable {
        public let maxID: String?
        public let minID: String?
        public let sinceID: String?
    }

    public let result: T
    public let info: Info
}
