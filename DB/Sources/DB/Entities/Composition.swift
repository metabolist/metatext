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
}

extension Composition {
    convenience init(record: CompositionRecord) {
        self.init(id: record.id, text: record.text)
    }
}
