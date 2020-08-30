// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct MastodonList: Codable, Hashable, Identifiable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}
