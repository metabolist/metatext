// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum StatusEndpoint {
    case status(id: Status.Id)
    case favourite(id: Status.Id)
    case unfavourite(id: Status.Id)
    case bookmark(id: Status.Id)
    case unbookmark(id: Status.Id)
    case post(Components)
}

public extension StatusEndpoint {
    struct Components {
        public let inReplyToId: Status.Id?
        public let text: String
        public let mediaIds: [Attachment.Id]

        public init(inReplyToId: Status.Id?, text: String, mediaIds: [Attachment.Id]) {
            self.inReplyToId = inReplyToId
            self.text = text
            self.mediaIds = mediaIds
        }
    }
}

extension StatusEndpoint.Components {
    var jsonBody: [String: Any]? {
        var params = [String: Any]()

        if !text.isEmpty {
            params["status"] = text
        }

        if !mediaIds.isEmpty {
            params["media_ids"] = mediaIds
        }

        params["in_reply_to_id"] = inReplyToId

        return params
    }
}

extension StatusEndpoint: Endpoint {
    public typealias ResultType = Status

    public var context: [String] {
        defaultContext + ["statuses"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case let .status(id):
            return [id]
        case let .favourite(id):
            return [id, "favourite"]
        case let .unfavourite(id):
            return [id, "unfavourite"]
        case let .bookmark(id):
            return [id, "bookmark"]
        case let .unbookmark(id):
            return [id, "unbookmark"]
        case .post:
            return []
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case let .post(components):
            return components.jsonBody
        default:
            return nil
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .status:
            return .get
        case .favourite, .unfavourite, .bookmark, .unbookmark, .post:
            return .post
        }
    }
}
