// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import GRDB
import Mastodon

public class Composition {
    public let id: Id
    @Published public var text: String
    @Published public var attachments: [Attachment]

    public init(id: Id, text: String) {
        self.id = id
        self.text = text
        attachments = []
    }
}

public extension Composition {
    typealias Id = UUID

    struct Attachment {
        public let data: Data
        public let type: Mastodon.Attachment.AttachmentType
        public let mimeType: String
        public var description: String?
        public var focus: Mastodon.Attachment.Meta.Focus?

        public init(data: Data, type: Mastodon.Attachment.AttachmentType, mimeType: String) {
            self.data = data
            self.type = type
            self.mimeType = mimeType
        }
    }
}

extension Composition {
    convenience init(record: CompositionRecord) {
        self.init(id: record.id, text: record.text)
    }
}
