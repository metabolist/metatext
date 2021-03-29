// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct PushSubscription: Codable {
    public struct Alerts: Codable, Hashable {
        public var follow: Bool
        public var favourite: Bool
        public var reblog: Bool
        public var mention: Bool
        @DecodableDefault.True public var followRequest: Bool
        @DecodableDefault.True public var poll: Bool
        @DecodableDefault.True public var status: Bool
    }

    public let endpoint: UnicodeURL
    public let alerts: Alerts
    public let serverKey: String
}

public extension PushSubscription.Alerts {
    static let initial: Self = Self(
        follow: true,
        favourite: true,
        reblog: true,
        mention: true,
        followRequest: DecodableDefault.True(),
        poll: DecodableDefault.True(),
        status: DecodableDefault.True())
}
