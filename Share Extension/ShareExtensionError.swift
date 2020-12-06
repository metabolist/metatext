// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

enum ShareExtensionError: Error {
    case noAccountFound
}

extension ShareExtensionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noAccountFound:
            return NSLocalizedString("share-extension-error.no-account-found", comment: "")
        }
    }
}
