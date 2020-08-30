// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct PushSubscription: Codable {
    public struct Alerts: Codable, Hashable {
        public var follow: Bool
        public var favourite: Bool
        public var reblog: Bool
        public var mention: Bool
        @DecodableDefault.True public var poll: Bool
    }

    public let endpoint: URL
    public let alerts: Alerts
    public let serverKey: String
}

public extension PushSubscription.Alerts {
    static let initial: Self = Self(
        follow: true,
        favourite: true,
        reblog: true,
        mention: true,
        poll: DecodableDefault.True())
}
