// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import GRDB

struct CompositionRecord: Codable, FetchableRecord, PersistableRecord {
    let id: Composition.Id
    let text: String
}
