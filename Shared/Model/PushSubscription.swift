// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct PushSubscription: Codable {
    struct Alerts: Codable, Hashable {
        let follow: Bool
        let favourite: Bool
        let reblog: Bool
        let mention: Bool
        let poll: Bool
    }

    let endpoint: URL
    let alerts: Alerts
    let serverKey: String
}
