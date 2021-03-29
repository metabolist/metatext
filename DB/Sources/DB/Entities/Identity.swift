// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public struct Identity: Codable, Hashable, Identifiable {
    public let id: Id
    public let url: URL
    public let authenticated: Bool
    public let pending: Bool
    public let lastUsedAt: Date
    public let preferences: Identity.Preferences
    public let instance: Identity.Instance?
    public let account: Identity.Account?
    public let lastRegisteredDeviceToken: Data?
    public let pushSubscriptionAlerts: PushSubscription.Alerts
}

public extension Identity {
    typealias Id = UUID

    struct Instance: Codable, Hashable {
        public let uri: String
        public let streamingAPI: UnicodeURL
        public let title: String
        public let thumbnail: UnicodeURL?
        public let version: String
        public let maxTootChars: Int?
    }

    struct Account: Codable, Hashable {
        public let id: Mastodon.Account.Id
        public let identityId: Identity.Id
        public let username: String
        public let displayName: String
        public let url: String
        public let avatar: UnicodeURL
        public let avatarStatic: UnicodeURL
        public let header: UnicodeURL
        public let headerStatic: UnicodeURL
        public let emojis: [Emoji]
        public let followRequestCount: Int
    }

    struct Preferences: Codable, Hashable {
        @DecodableDefault.True public var useServerPostingReadingPreferences
        @DecodableDefault.StatusVisibilityPublic public var postingDefaultVisibility: Status.Visibility
        @DecodableDefault.False public var postingDefaultSensitive
        public var postingDefaultLanguage: String?
        @DecodableDefault.ExpandMediaDefault public var readingExpandMedia: Mastodon.Preferences.ExpandMedia
        @DecodableDefault.False public var readingExpandSpoilers
    }

    var handle: String {
        if let urlString = account?.url, let url = URL(string: urlString), let host = url.host {
            return url.lastPathComponent.appending("@").appending(host)
        }

        return instance?.title ?? url.host ?? url.absoluteString
    }

    var image: URL? { (account?.avatar ?? instance?.thumbnail)?.url }
}

public extension Identity.Preferences {
    func updated(from serverPreferences: Preferences) -> Self {
        var mutable = self

        if useServerPostingReadingPreferences {
            mutable.postingDefaultVisibility = serverPreferences.postingDefaultVisibility
            mutable.postingDefaultSensitive = serverPreferences.postingDefaultSensitive
            mutable.readingExpandMedia = serverPreferences.readingExpandMedia
            mutable.readingExpandSpoilers = serverPreferences.readingExpandSpoilers
        }

        return mutable
    }
}
