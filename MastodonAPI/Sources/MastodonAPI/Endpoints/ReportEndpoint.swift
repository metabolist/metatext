// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum ReportEndpoint {
    case create(Elements)
}

public extension ReportEndpoint {
    struct Elements {
        public let accountId: Account.Id
        public var statusIds = Set<Status.Id>()
        public var comment = ""
        public var forward = false

        public init(accountId: Account.Id) {
            self.accountId = accountId
        }
    }
}

extension ReportEndpoint: Endpoint {
    public typealias ResultType = Report

    public var context: [String] {
        defaultContext + ["reports"]
    }

    public var pathComponentsInContext: [String] {
        []
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case let .create(creation):
            var params: [String: Any] = ["account_id": creation.accountId]

            if !creation.statusIds.isEmpty {
                params["status_ids"] = Array(creation.statusIds)
            }

            if !creation.comment.isEmpty {
                params["comment"] = creation.comment
            }

            if creation.forward {
                params["forward"] = creation.forward
            }

            return params
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        }
    }
}
