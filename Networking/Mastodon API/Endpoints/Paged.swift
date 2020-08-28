// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct Paged<T: MastodonEndpoint> {
    let endpoint: T
    let maxID: String?
    let minID: String?
    let sinceID: String?
    let limit: Int?

    init(_ endpoint: T, maxID: String? = nil, minID: String? = nil, sinceID: String? = nil, limit: Int? = nil) {
        self.endpoint = endpoint
        self.maxID = maxID
        self.minID = minID
        self.sinceID = sinceID
        self.limit = limit
    }
}

extension Paged: MastodonEndpoint {
    typealias ResultType = T.ResultType

    var APIVersion: String { endpoint.APIVersion }

    var context: [String] { endpoint.context }

    var pathComponentsInContext: [String] { endpoint.pathComponentsInContext }

    var method: HTTPMethod { endpoint.method }

    var encoding: ParameterEncoding { endpoint.encoding }

    var parameters: [String: Any]? {
        var parameters = endpoint.parameters ?? [String: Any]()

        parameters["max_id"] = maxID
        parameters["min_id"] = minID
        parameters["since_id"] = sinceID
        parameters["limit"] = limit

        return parameters
    }

    var headers: HTTPHeaders? { endpoint.headers }
}
