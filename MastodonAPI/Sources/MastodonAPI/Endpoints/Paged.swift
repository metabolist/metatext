// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public struct Paged<T: Endpoint> {
    public let endpoint: T
    public let maxId: String?
    public let minId: String?
    public let sinceId: String?
    public let limit: Int?

    public init(_ endpoint: T, maxId: String? = nil, minId: String? = nil, sinceId: String? = nil, limit: Int? = nil) {
        self.endpoint = endpoint
        self.maxId = maxId
        self.minId = minId
        self.sinceId = sinceId
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

        queryParameters["max_id"] = maxId
        queryParameters["min_id"] = minId
        queryParameters["since_id"] = sinceId

        if let limit = limit {
            queryParameters["limit"] = String(limit)
        }

        return queryParameters
    }

    public var headers: [String: String]? { endpoint.headers }
}

public struct PagedResult<T: Decodable>: Decodable {
    public struct Info: Decodable {
        public let maxId: String?
        public let minId: String?
        public let sinceId: String?
    }

    public let result: T
    public let info: Info
}
