// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Preferences: Codable {
    enum CodingKeys: String, CodingKey {
        case postingDefaultVisibility = "posting:default:visibility"
        case postingDefaultSensitive = "posting:default:sensitive"
        case postingDefaultLanguage = "posting:default:language"
        case readingExpandMedia = "reading:expand:media"
        case readingExpandSpoilers = "reading:expand:spoilers"
    }

    public let postingDefaultVisibility: Status.Visibility
    public let postingDefaultSensitive: Bool
    public let postingDefaultLanguage: String?
    public let readingExpandMedia: ExpandMedia
    public let readingExpandSpoilers: Bool
}

public extension Preferences {
    enum ExpandMedia: String, Codable, Unknowable {
        case `default`
        case showAll
        case hideAll
        case unknown

        public static var unknownCase: Self { .unknown }
    }
}
