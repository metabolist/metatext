// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct MastodonPreferences: Codable {
    enum CodingKeys: String, CodingKey {
        case postingDefaultVisibility = "posting:default:visibility"
        case postingDefaultSensitive = "posting:default:sensitive"
        case postingDefaultLanguage = "posting:default:language"
        case readingExpandMedia = "reading:expand:media"
        case readingExpandSpoilers = "reading:expand:spoilers"
    }

    let postingDefaultVisibility: Status.Visibility
    let postingDefaultSensitive: Bool
    let postingDefaultLanguage: String?
    let readingExpandMedia: ExpandMedia
    let readingExpandSpoilers: Bool
}

extension MastodonPreferences {
    enum ExpandMedia: String, Codable, Unknowable {
        case `default`
        case showAll
        case hideAll
        case unknown

        static var unknownCase: Self { .unknown }
    }
}
