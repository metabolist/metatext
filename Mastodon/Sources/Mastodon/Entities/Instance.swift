// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Instance: Codable, Hashable {
    public struct URLs: Codable, Hashable {
        public let streamingApi: URL
    }

    public struct Stats: Codable, Hashable {
        public let userCount: Int
        public let statusCount: Int
        public let domainCount: Int
    }

    public let uri: String
    public let title: String
    public let description: String
    public let shortDescription: String?
    public let email: String
    public let version: String
    @DecodableDefault.EmptyList public private(set) var languages: [String]
    @DecodableDefault.False public private(set) var registrations: Bool
    @DecodableDefault.False public private(set) var approvalRequired: Bool
    @DecodableDefault.False public private(set) var invitesEnabled: Bool
    public let urls: URLs
    public let stats: Stats
    public let thumbnail: URL?
    public let contactAccount: Account?
    public let maxTootChars: Int?
}
