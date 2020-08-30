// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Paged<T: MastodonEndpoint> {
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

extension Paged: MastodonEndpoint {
    public typealias ResultType = T.ResultType

    public var APIVersion: String { endpoint.APIVersion }

    public var context: [String] { endpoint.context }

    public var pathComponentsInContext: [String] { endpoint.pathComponentsInContext }

    public var method: HTTPMethod { endpoint.method }

    public var encoding: ParameterEncoding { endpoint.encoding }

    public var parameters: [String: Any]? {
        var parameters = endpoint.parameters ?? [String: Any]()

        parameters["max_id"] = maxID
        parameters["min_id"] = minID
        parameters["since_id"] = sinceID
        parameters["limit"] = limit

        return parameters
    }

    public var headers: HTTPHeaders? { endpoint.headers }
}
