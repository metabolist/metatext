// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct List: Codable, Hashable, Identifiable {
    public let id: Id
    public let title: String

    public init(id: Id, title: String) {
        self.id = id
        self.title = title
    }
}

public extension List {
    typealias Id = String
}
