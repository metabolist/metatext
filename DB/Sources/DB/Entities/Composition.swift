// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

public class Composition {
    public let id: Id
    public var text: String

    public init(id: Id, text: String) {
        self.id = id
        self.text = text
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
