// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct Identity: Codable, Hashable, Identifiable {
    let id: UUID
    let url: URL
    let lastUsedAt: Date
    let preferences: Identity.Preferences
    let instance: Identity.Instance?
    let account: Identity.Account?
    let lastRegisteredDeviceToken: String?
    let pushSubscriptionAlerts: PushSubscription.Alerts
}

extension Identity {
    struct Instance: Codable, Hashable {
        let uri: String
        let streamingAPI: URL
        let title: String
        let thumbnail: URL?
    }

    struct Account: Codable, Hashable {
        let id: String
        let identityID: UUID
        let username: String
        let displayName: String
        let url: URL
        let avatar: URL
        let avatarStatic: URL
        let header: URL
        let headerStatic: URL
        let emojis: [Emoji]
    }

    struct Preferences: Codable, Hashable {
        @DecodableDefault.True var useServerPostingReadingPreferences
        @DecodableDefault.StatusVisibilityPublic var postingDefaultVisibility: Status.Visibility
        @DecodableDefault.False var postingDefaultSensitive
        var postingDefaultLanguage: String?
        @DecodableDefault.ExpandMediaDefault var readingExpandMedia: MastodonPreferences.ExpandMedia
        @DecodableDefault.False var readingExpandSpoilers
    }
}

extension Identity {
    var handle: String {
        if let account = account, let host = account.url.host {
            return account.url.lastPathComponent + "@" + host
        }

        return instance?.title ?? url.host ?? url.absoluteString
    }

    var image: URL? { account?.avatar ?? instance?.thumbnail }
}

extension Identity.Preferences {
    func updated(from serverPreferences: MastodonPreferences) -> Self {
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
