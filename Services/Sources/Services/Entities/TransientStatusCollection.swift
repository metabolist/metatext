// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct TransientStatusCollection: Codable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}
