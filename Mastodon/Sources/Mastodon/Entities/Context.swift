// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Context: Codable, Hashable {
    public let ancestors: [Status]
    public let descendants: [Status]

    public init(ancestors: [Status], descendants: [Status]) {
        self.ancestors = ancestors
        self.descendants = descendants
    }
}
