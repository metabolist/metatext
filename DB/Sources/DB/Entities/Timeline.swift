// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public enum Timeline: Hashable {
    case home
    case local
    case federated
    case list(List)
    case tag(String)
    case profile(accountId: Account.Id, profileCollection: ProfileCollection)
    case favorites
    case bookmarks
}

public extension Timeline {
    typealias Id = String

    static let unauthenticatedDefaults: [Timeline] = [.local, .federated]
    static let authenticatedDefaults: [Timeline] = [.home, .local, .federated]

    var filterContext: Filter.Context? {
        switch self {
        case .home, .list:
            return .home
        case .local, .federated, .tag:
            return .public
        case .profile:
            return .account
        default:
            return nil
        }
    }
}

extension Timeline: Identifiable {
    public var id: Id {
        switch self {
        case .home:
            return "home"
        case .local:
            return "local"
        case .federated:
            return "federated"
        case let .list(list):
            return "list-".appending(list.id)
        case let .tag(tag):
            return "tag-".appending(tag).lowercased()
        case let .profile(accountId, profileCollection):
            return "profile-\(accountId)-\(profileCollection)"
        case .favorites:
            return "favorites"
        case .bookmarks:
            return "bookmarks"
        }
    }
}
