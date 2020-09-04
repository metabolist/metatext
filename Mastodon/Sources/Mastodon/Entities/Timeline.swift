// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum Timeline: Hashable {
    case home
    case local
    case federated
    case list(MastodonList)
    case tag(String)
}

public extension Timeline {
    static let nonLists: [Timeline] = [.home, .local, .federated]
}

extension Timeline: Identifiable {
    public var id: String {
        switch self {
        case .home:
            return "home"
        case .local:
            return "local"
        case .federated:
            return "federated"
        case let .list(list):
            return list.id
        case let .tag(tag):
            return "#" + tag
        }
    }
}
