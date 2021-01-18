// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum FeaturedTagsEndpoint {
    case featuredTags(id: Account.Id)
}

extension FeaturedTagsEndpoint: Endpoint {
    public typealias ResultType = [FeaturedTag]

    public var context: [String] {
        switch self {
        case .featuredTags:
            return defaultContext + ["accounts"]
        }

    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .featuredTags(id):
            return [id, "featured_tags"]
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .featuredTags:
            return .get
        }
    }
}
