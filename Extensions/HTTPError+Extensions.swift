// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import HTTP

extension HTTPError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .nonHTTPURLResponse:
            return NSLocalizedString("http-error.non-http-response", comment: "")
        case let .invalidStatusCode(_, response):
            return String.localizedStringWithFormat(
                NSLocalizedString("http-error.status-code-%ld", comment: ""),
                response.statusCode)
        }
    }
}
