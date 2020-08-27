// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct Mention: Codable, Hashable {
    let url: URL
    let username: String
    let acct: String
    let id: String
}
