// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum ResultsEndpoint {
    case search(Search)
}

public extension ResultsEndpoint {
    struct Search {
        public let query: String
        public let type: SearchType?
        public let excludeUnreviewed: Bool
        public let resolve: Bool
        public let limit: Int?
        public let offset: Int?
        public let following: Bool

        public init(query: String,
                    type: SearchType? = nil,
                    excludeUnreviewed: Bool = false,
                    resolve: Bool = true,
                    limit: Int? = nil,
                    offset: Int? = nil,
                    following: Bool = false) {
            self.query = query
            self.type = type
            self.excludeUnreviewed = excludeUnreviewed
            self.resolve = resolve
            self.limit = limit
            self.offset = offset
            self.following = following
        }
    }
}

public extension ResultsEndpoint.Search {
    enum SearchType: String {
        case accounts
        case hashtags
        case statuses
    }
}

extension ResultsEndpoint: Endpoint {
    public typealias ResultType = Results

    public var APIVersion: String {
        switch self {
        case .search:
            return "v2"
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .search:
            return ["search"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .search:
            return .get
        }
    }

    public var queryParameters: [URLQueryItem] {
        switch self {
        case let .search(search):
            var params = [URLQueryItem(name: "q", value: search.query)]

            if let type = search.type {
                params.append(.init(name: "type", value: type.rawValue))
            }

            if search.excludeUnreviewed {
                params.append(.init(name: "exclude_unreviewed", value: "true"))
            }

            if search.resolve {
                params.append(.init(name: "resolve", value: "true"))
            }

            if let limit = search.limit {
                params.append(.init(name: "limit", value: String(limit)))
            }

            if let offset = search.offset {
                params.append(.init(name: "offset", value: String(offset)))
            }

            if search.following {
                params.append(.init(name: "following", value: "true"))
            }

            return params
        }
    }
}
