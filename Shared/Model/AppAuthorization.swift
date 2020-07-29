// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct AppAuthorization: Codable {
    let id: String
    let clientId: String
    let clientSecret: String
    let name: String
    let redirectUri: String
    let website: String?
    let vapidKey: String?
}
