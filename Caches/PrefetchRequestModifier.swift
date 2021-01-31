// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import Kingfisher

struct PrefetchRequestModifier: ImageDownloadRequestModifier {
    func modified(for request: URLRequest) -> URLRequest? {
        var mutableRequest = request

        mutableRequest.allowsExpensiveNetworkAccess = false
        mutableRequest.allowsConstrainedNetworkAccess = false

        return request
    }
}
