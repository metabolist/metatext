// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Instance: Codable, Hashable {
    public struct URLs: Codable, Hashable {
        public let streamingApi: UnicodeURL
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
    public let thumbnail: UnicodeURL?
    public let contactAccount: Account?
    public let maxTootChars: Int?

    public init(uri: String,
                title: String,
                description: String,
                shortDescription: String?,
                email: String,
                version: String,
                urls: Instance.URLs,
                stats: Instance.Stats,
                thumbnail: UnicodeURL?,
                contactAccount: Account?,
                maxTootChars: Int?) {
        self.uri = uri
        self.title = title
        self.description = description
        self.shortDescription = shortDescription
        self.email = email
        self.version = version
        self.urls = urls
        self.stats = stats
        self.thumbnail = thumbnail
        self.contactAccount = contactAccount
        self.maxTootChars = maxTootChars
    }
}

public extension Instance {
    var majorVersion: Int? {
        guard let majorVersionString = version.split(separator: ".").first else { return nil }

        return Int(majorVersionString)
    }

    var minorVersion: Int? {
        let versionComponents = version.split(separator: ".")

        guard versionComponents.count > 1 else { return nil }

        return Int(versionComponents[1])
    }

    var patchVersion: String? {
        let versionComponents = version.split(separator: ".")

        guard versionComponents.count > 2 else { return nil }

        return String(versionComponents[2])
    }

    var canShowProfileDirectory: Bool {
        guard let majorVersion = majorVersion else { return false }

        return majorVersion >= 3
    }
}
