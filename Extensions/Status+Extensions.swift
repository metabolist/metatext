// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

extension Status.Visibility {
    var systemImageName: String {
        switch self {
        case .public:
            return "network"
        case .unlisted:
            return "lock.open"
        case .private:
            return "lock"
        case .direct:
            return "envelope"
        case .unknown:
            return "questionmark"
        }
    }

    var title: String? {
        switch self {
        case .public:
            return NSLocalizedString("status.visibility.public", comment: "")
        case .unlisted:
            return NSLocalizedString("status.visibility.unlisted", comment: "")
        case .private:
            return NSLocalizedString("status.visibility.private", comment: "")
        case .direct:
            return NSLocalizedString("status.visibility.direct", comment: "")
        case .unknown:
            return nil
        }
    }

    var description: String? {
        switch self {
        case .public:
            return NSLocalizedString("status.visibility.public.description", comment: "")
        case .unlisted:
            return NSLocalizedString("status.visibility.unlisted.description", comment: "")
        case .private:
            return NSLocalizedString("status.visibility.private.description", comment: "")
        case .direct:
            return NSLocalizedString("status.visibility.direct.description", comment: "")
        case .unknown:
            return nil
        }
    }
}
