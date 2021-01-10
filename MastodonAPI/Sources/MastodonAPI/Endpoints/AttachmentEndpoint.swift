// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum AttachmentEndpoint {
    case create(data: Data, mimeType: String, description: String?, focus: Attachment.Meta.Focus?)
    case update(id: Attachment.Id, description: String?, focus: Attachment.Meta.Focus?)
}

extension AttachmentEndpoint: Endpoint {
    public typealias ResultType = Attachment

    public var context: [String] {
        defaultContext + ["media"]
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .create:
            return []
        case let .update(id, _, _):
            return [id]
        }
    }

    public var multipartFormData: [String: MultipartFormValue]? {
        switch self {
        case let .create(data, mimeType, description, focus):
            var params = [String: MultipartFormValue]()

            params["file"] = .data(data, filename: UUID().uuidString, mimeType: mimeType)

            if let description = description {
                params["description"] = .string(description)
            }

            if let focus = focus {
                params["focus"] = .string("\(focus.x),\(focus.y)")
            }

            return params
        case let .update(_, description, focus):
            var params = [String: MultipartFormValue]()

            if let description = description {
                params["description"] = .string(description)
            }

            if let focus = focus {
                params["focus"] = .string("\(focus.x),\(focus.y)")
            }

            return params
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        case .update:
            return .put
        }
    }
}
