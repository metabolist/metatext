// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum StatusesEndpoint {
    case timelinesPublic(local: Bool)
    case timelinesTag(String)
    case timelinesHome
    case timelinesList(id: List.Id)
    case accountsStatuses(id: Account.Id, excludeReplies: Bool, onlyMedia: Bool, pinned: Bool)
}

extension StatusesEndpoint: Endpoint {
    public typealias ResultType = [Status]

    public var context: [String] {
        switch self {
        case .timelinesPublic, .timelinesTag, .timelinesHome, .timelinesList:
            return defaultContext + ["timelines"]
        case .accountsStatuses:
            return defaultContext + ["accounts"]
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .timelinesPublic:
            return ["public"]
        case let .timelinesTag(tag):
            return ["tag", tag]
        case .timelinesHome:
            return ["home"]
        case let .timelinesList(id):
            return ["list", id]
        case let .accountsStatuses(id, _, _, _):
            return [id, "statuses"]
        }
    }

    public var queryParameters: [String: String]? {
        switch self {
        case let .timelinesPublic(local):
            return ["local": String(local)]
        case let .accountsStatuses(_, excludeReplies, onlyMedia, pinned):
            return ["exclude_replies": String(excludeReplies),
                    "only_media": String(onlyMedia),
                    "pinned": String(pinned)]
        default:
            return nil
        }
    }

    public var method: HTTPMethod { .get }
}
