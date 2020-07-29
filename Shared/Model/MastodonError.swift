// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct MastodonError: Error, Codable {
    let error: String
}

extension MastodonError: LocalizedError {
    var errorDescription: String? { error }
}
