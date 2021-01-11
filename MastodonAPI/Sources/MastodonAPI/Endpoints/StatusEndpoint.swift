// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum StatusEndpoint {
    case status(id: Status.Id)
    case reblog(id: Status.Id)
    case unreblog(id: Status.Id)
    case favourite(id: Status.Id)
    case unfavourite(id: Status.Id)
    case bookmark(id: Status.Id)
    case unbookmark(id: Status.Id)
    case pin(id: Status.Id)
    case unpin(id: Status.Id)
    case mute(id: Status.Id)
    case unmute(id: Status.Id)
    case delete(id: Status.Id)
    case post(Components)
}

public extension StatusEndpoint {
    struct Components {
        public let inReplyToId: Status.Id?
        public let text: String
        public let spoilerText: String
        public let mediaIds: [Attachment.Id]
        public let visibility: Status.Visibility
        public let sensitive: Bool
        public let pollOptions: [String]
        public let pollExpiresIn: Int
        public let pollMultipleChoice: Bool

        public init(
            inReplyToId: Status.Id?,
            text: String,
            spoilerText: String,
            mediaIds: [Attachment.Id],
            visibility: Status.Visibility,
            sensitive: Bool,
            pollOptions: [String],
            pollExpiresIn: Int,
            pollMultipleChoice: Bool) {
            self.inReplyToId = inReplyToId
            self.text = text
            self.spoilerText = spoilerText
            self.mediaIds = mediaIds
            self.visibility = visibility
            self.sensitive = sensitive
            self.pollOptions = pollOptions
            self.pollExpiresIn = pollExpiresIn
            self.pollMultipleChoice = pollMultipleChoice
        }
    }
}

extension StatusEndpoint.Components {
    var jsonBody: [String: Any]? {
        var params = [String: Any]()

        if !text.isEmpty {
            params["status"] = text
        }

        if !spoilerText.isEmpty {
            params["spoiler_text"] = spoilerText
        }

        if !mediaIds.isEmpty {
            params["media_ids"] = mediaIds
        }

        params["in_reply_to_id"] = inReplyToId
        params["visibility"] = visibility.rawValue

        if sensitive {
            params["sensitive"] = true
        }

        if !pollOptions.isEmpty {
            var poll = [String: Any]()

            poll["options"] = pollOptions
            poll["expires_in"] = pollExpiresIn
            poll["multiple"] = pollMultipleChoice

            params["poll"] = poll
        }

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
        case let .status(id), let .delete(id):
            return [id]
        case let .reblog(id):
            return [id, "reblog"]
        case let .unreblog(id):
            return [id, "unreblog"]
        case let .favourite(id):
            return [id, "favourite"]
        case let .unfavourite(id):
            return [id, "unfavourite"]
        case let .bookmark(id):
            return [id, "bookmark"]
        case let .unbookmark(id):
            return [id, "unbookmark"]
        case let .pin(id):
            return [id, "pin"]
        case let .unpin(id):
            return [id, "unpin"]
        case let .mute(id):
            return [id, "mute"]
        case let .unmute(id):
            return [id, "unmute"]
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
        case .delete:
            return .delete
        default:
            return .post
        }
    }
}
