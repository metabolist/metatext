// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct MastodonContext: Codable, Hashable {
    let ancestors: [Status]
    let descendants: [Status]
}
