// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct PushSubscription: Codable {
    struct Alerts: Codable, Hashable {
        var follow: Bool
        var favourite: Bool
        var reblog: Bool
        var mention: Bool
        var poll: Bool
    }

    let endpoint: URL
    let alerts: Alerts
    let serverKey: String
}

extension PushSubscription.Alerts {
    static let initial: Self = Self(follow: true, favourite: true, reblog: true, mention: true, poll: true)
}
