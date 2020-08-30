// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum ListsEndpoint {
    case lists
}

extension ListsEndpoint: Endpoint {
    public typealias ResultType = [MastodonList]

    public var pathComponentsInContext: [String] {
        ["lists"]
    }

    public var method: HTTPMethod {
        .get
    }
}
