// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum ListsEndpoint {
    case lists
}

extension ListsEndpoint: MastodonEndpoint {
    typealias ResultType = [MastodonList]

    var pathComponentsInContext: [String] {
        ["lists"]
    }

    var method: HTTPMethod {
        .get
    }
}
