// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Mastodon

public struct Identity: Codable, Hashable, Identifiable {
    public let id: UUID
    public let url: URL
    public let lastUsedAt: Date
    public let preferences: Identity.Preferences
    public let instance: Identity.Instance?
    public let account: Identity.Account?
    public let lastRegisteredDeviceToken: Data?
    public let pushSubscriptionAlerts: PushSubscription.Alerts
}

public extension Identity {
    struct Instance: Codable, Hashable {
        public let uri: String
        public let streamingAPI: URL
        public let title: String
        public let thumbnail: URL?
    }

    struct Account: Codable, Hashable {
        public let id: String
        public let identityID: UUID
        public let username: String
        public let displayName: String
        public let url: URL
        public let avatar: URL
        public let avatarStatic: URL
        public let header: URL
        public let headerStatic: URL
        public let emojis: [Emoji]
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
        if let account = account, let host = account.url.host {
            return account.url.lastPathComponent + "@" + host
        }

        return instance?.title ?? url.host ?? url.absoluteString
    }

    var image: URL? { account?.avatar ?? instance?.thumbnail }
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
