// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import ViewModels

extension AccountStatusCollection {
    var title: String {
        switch self {
        case .statuses:
            return NSLocalizedString("account.statuses", comment: "")
        case .statusesAndReplies:
            return NSLocalizedString("account.statuses-and-replies", comment: "")
        case .media:
            return NSLocalizedString("account.media", comment: "")
        }
    }
}
