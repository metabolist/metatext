// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import ViewModels

extension ProfileCollection {
    func title(statusWord: AppPreferences.StatusWord) -> String {
        switch self {
        case .statuses:
            switch statusWord {
            case .toot:
                return NSLocalizedString("account.statuses.toot", comment: "")
            case .post:
                return NSLocalizedString("account.statuses.post", comment: "")
            }
        case .statusesAndReplies:
            switch statusWord {
            case .toot:
                return NSLocalizedString("account.statuses-and-replies.toot", comment: "")
            default:
                return NSLocalizedString("account.statuses-and-replies.post", comment: "")
            }
        case .media:
            return NSLocalizedString("account.media", comment: "")
        }
    }
}
