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
    case favourites
    case bookmarks
}

extension StatusesEndpoint: Endpoint {
    public typealias ResultType = [Status]

    public var context: [String] {
        switch self {
        case .timelinesPublic, .timelinesTag, .timelinesHome, .timelinesList:
            return defaultContext + ["timelines"]
        case .accountsStatuses:
            return defaultContext + ["accounts"]
        case .favourites, .bookmarks:
            return defaultContext
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
        case .favourites:
            return ["favourites"]
        case .bookmarks:
            return ["bookmarks"]
        }
    }

    public var queryParameters: [URLQueryItem] {
        switch self {
        case let .timelinesPublic(local):
            return [URLQueryItem(name: "local", value: String(local))]
        case let .accountsStatuses(_, excludeReplies, onlyMedia, pinned):
            return [URLQueryItem(name: "exclude_replies", value: String(excludeReplies)),
                    URLQueryItem(name: "only_media", value: String(onlyMedia)),
                    URLQueryItem(name: "pinned", value: String(pinned))]
        default:
            return []
        }
    }

    public var method: HTTPMethod { .get }
}
