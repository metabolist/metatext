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

    var ordered: Bool {
        switch self {
        case .favorites, .bookmarks:
            return true
        default:
            return false
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

extension Timeline {
    init?(record: TimelineRecord) {
        switch (record.id,
                record.listId,
                record.listTitle,
                record.tag,
                record.accountId,
                record.profileCollection) {
        case (Timeline.home.id, _, _, _, _, _):
            self = .home
        case (Timeline.local.id, _, _, _, _, _):
            self = .local
        case (Timeline.federated.id, _, _, _, _, _):
            self = .federated
        case (_, .some(let listId), .some(let listTitle), _, _, _):
            self = .list(List(id: listId, title: listTitle))
        case (_, _, _, .some(let tag), _, _):
            self = .tag(tag)
        case (_, _, _, _, .some(let accountId), .some(let profileCollection)):
            self = .profile(accountId: accountId, profileCollection: profileCollection)
        case (Timeline.favorites.id, _, _, _, _, _):
            self = .favorites
        case (Timeline.bookmarks.id, _, _, _, _, _):
            self = .bookmarks
        default:
            return nil
        }
    }

    func ephemeralityId(id: Identity.Id) -> String? {
        switch self {
        case .tag, .favorites, .bookmarks:
            return "\(id)-\(self.id)"
        default:
            return nil
        }
    }
}
