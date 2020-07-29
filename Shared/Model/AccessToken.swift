// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct AccessToken: Codable {
    let scope: String
    let tokenType: String
    let accessToken: String
}
