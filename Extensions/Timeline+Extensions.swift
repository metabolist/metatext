// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import ViewModels

extension Timeline {
    var title: String {
        switch self {
        case .home:
            return NSLocalizedString("timelines.home", comment: "")
        case .local:
            return NSLocalizedString("timelines.local", comment: "")
        case .federated:
            return NSLocalizedString("timelines.federated", comment: "")
        case let .list(list):
            return list.title
        case let .tag(tag):
            return "#".appending(tag)
        case .profile:
            return ""
        case .favorites:
            return NSLocalizedString("favorites", comment: "")
        case .bookmarks:
            return NSLocalizedString("bookmarks", comment: "")
        }
    }

    var systemImageName: String {
        switch self {
        case .home: return "house"
        case .local: return "building.2.crop.circle"
        case .federated: return "network"
        case .list: return "scroll"
        case .tag: return "number"
        case .profile: return "person"
        case .favorites: return "star"
        case .bookmarks: return "bookmark"
        }
    }
}
