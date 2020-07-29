// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct MastodonAPI {
    static let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

    struct OAuth {
        static let clientName = "Metatext"
        static let scopes = "read write follow push"
        static let codeCallbackQueryItemName = "code"
        static let grantType = "authorization_code"
        static let callbackURLScheme = "metatext"
    }

    enum OAuthError {
        case codeNotFound
    }
}

extension MastodonAPI.OAuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .codeNotFound:
            return NSLocalizedString("oauth.error.code-not-found", comment: "")
        }
    }
}
