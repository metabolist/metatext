// Copyright © 2020 Metabolist. All rights reserved.

import CodableBloomFilter
import Foundation
import Mastodon

public struct AppPreferences {
    private let userDefaults: UserDefaults
    private let systemReduceMotion: () -> Bool
    private let systemAutoplayVideos: () -> Bool

    public init(environment: AppEnvironment) {
        self.userDefaults = environment.userDefaults
        self.systemReduceMotion = environment.reduceMotion
        self.systemAutoplayVideos = environment.autoplayVideos
    }
}

public extension AppPreferences {
    enum StatusWord: String, CaseIterable, Identifiable {
        case toot
        case post

        public var id: String { rawValue }
    }

    enum AnimateAvatars: String, CaseIterable, Identifiable {
        case everywhere
        case profiles
        case never

        public var id: String { rawValue }
    }

    enum Autoplay: String, CaseIterable, Identifiable {
        case always
        case wifi
        case never

        public var id: String { rawValue }
    }

    enum PositionBehavior: String, CaseIterable, Identifiable {
        case localRememberPosition
        case newest

        public var id: String { rawValue }
    }

    var statusWord: StatusWord {
        get {
            if let rawValue = self[.statusWord] as String?,
               let value = StatusWord(rawValue: rawValue) {
                return value
            }

            return .toot
        }
        set { self[.statusWord] = newValue.rawValue }
    }

    var animateAvatars: AnimateAvatars {
        get {
            if let rawValue = self[.animateAvatars] as String?,
               let value = AnimateAvatars(rawValue: rawValue) {
                return value
            }

            return systemReduceMotion() ? .never : .everywhere
        }
        set { self[.animateAvatars] = newValue.rawValue }
    }

    var animateHeaders: Bool {
        get { self[.animateHeaders] ?? !systemReduceMotion() }
        set { self[.animateHeaders] = newValue }
    }

    var animateCustomEmojis: Bool {
        get { self[.animateCustomEmojis] ?? !systemReduceMotion() }
        set { self[.animateCustomEmojis] = newValue }
    }

    var autoplayGIFs: Autoplay {
        get {
            if let rawValue = self[.autoplayGIFs] as String?,
               let value = Autoplay(rawValue: rawValue) {
                return value
            }

            return (!systemAutoplayVideos() || systemReduceMotion()) ? .never : .always
        }
        set { self[.autoplayGIFs] = newValue.rawValue }
    }

    var autoplayVideos: Autoplay {
        get {
            if let rawValue = self[.autoplayVideos] as String?,
               let value = Autoplay(rawValue: rawValue) {
                return value
            }

            return (!systemAutoplayVideos() || systemReduceMotion()) ? .never : .wifi
        }
        set { self[.autoplayVideos] = newValue.rawValue }
    }

    var homeTimelineBehavior: PositionBehavior {
        get {
            if let rawValue = self[.homeTimelineBehavior] as String?,
               let value = PositionBehavior(rawValue: rawValue) {
                return value
            }

            return .localRememberPosition
        }
        set { self[.homeTimelineBehavior] = newValue.rawValue }
    }

    var defaultEmojiSkinTone: SystemEmoji.SkinTone? {
        get {
            if let rawValue = self[.defaultEmojiSkinTone] as Int?,
               let value = SystemEmoji.SkinTone(rawValue: rawValue) {
                return value
            }

            return nil
        }
        set { self[.defaultEmojiSkinTone] = newValue?.rawValue }
    }

    var notificationSounds: Set<MastodonNotification.NotificationType> {
        get {
            Set((self[.notificationSounds] as [String]?)?.compactMap {
                MastodonNotification.NotificationType(rawValue: $0)
            } ?? MastodonNotification.NotificationType.allCasesExceptUnknown)
        }
        set { self[.notificationSounds] = newValue.map { $0.rawValue } }
    }

    func positionBehavior(timeline: Timeline) -> PositionBehavior {
        switch timeline {
        case .home:
            return homeTimelineBehavior
        default:
            return .newest
        }
    }

    var showReblogAndFavoriteCounts: Bool {
        get { self[.showReblogAndFavoriteCounts] ?? false }
        set { self[.showReblogAndFavoriteCounts] = newValue }
    }

    var requireDoubleTapToReblog: Bool {
        get { self[.requireDoubleTapToReblog] ?? false }
        set { self[.requireDoubleTapToReblog] = newValue }
    }

    var requireDoubleTapToFavorite: Bool {
        get { self[.requireDoubleTapToFavorite] ?? false }
        set { self[.requireDoubleTapToFavorite] = newValue }
    }

    var notificationPictures: Bool {
        get { self[.notificationPictures] ?? true }
        set { self[.notificationPictures] = newValue }
    }

    var notificationAccountName: Bool {
        get { self[.notificationAccountName] ?? false }
        set { self[.notificationAccountName] = newValue }
    }

    var openLinksInDefaultBrowser: Bool {
        get { self[.openLinksInDefaultBrowser] ?? false }
        set { self[.openLinksInDefaultBrowser] = newValue }
    }

    var useUniversalLinks: Bool {
        get { self[.useUniversalLinks] ?? true }
        set { self[.useUniversalLinks] = newValue }
    }
}

private extension AppPreferences {
    enum Item: String {
        case statusWord
        case requireDoubleTapToReblog
        case requireDoubleTapToFavorite
        case animateAvatars
        case animateHeaders
        case animateCustomEmojis
        case autoplayGIFs
        case autoplayVideos
        case homeTimelineBehavior
        case notificationsTabBehavior
        case defaultEmojiSkinTone
        case showReblogAndFavoriteCounts
        case notificationPictures
        case notificationAccountName
        case notificationSounds
        case openLinksInDefaultBrowser
        case useUniversalLinks
    }

    subscript<T>(index: Item) -> T? {
        get { userDefaults.value(forKey: index.rawValue) as? T }
        set { userDefaults.set(newValue, forKey: index.rawValue) }
    }
}
