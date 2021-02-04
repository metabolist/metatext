// Copyright © 2020 Metabolist. All rights reserved.

import CodableBloomFilter
import Foundation
import Mastodon

public struct AppPreferences {
    private let userDefaults: UserDefaults
    private let systemReduceMotion: () -> Bool

    public init(environment: AppEnvironment) {
        self.userDefaults = environment.userDefaults
        self.systemReduceMotion = environment.reduceMotion
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
        case rememberPosition
        case syncPosition
        case newest

        public var id: String { rawValue }
    }

    var useSystemReduceMotionForMedia: Bool {
        get { self[.useSystemReduceMotionForMedia] ?? true }
        set { self[.useSystemReduceMotionForMedia] = newValue }
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

            return .everywhere
        }
        set { self[.animateAvatars] = newValue.rawValue }
    }

    var animateHeaders: Bool {
        get { self[.animateHeaders] ?? true }
        set { self[.animateHeaders] = newValue }
    }

    var autoplayGIFs: Autoplay {
        get {
            if let rawValue = self[.autoplayGIFs] as String?,
               let value = Autoplay(rawValue: rawValue) {
                return value
            }

            return .always
        }
        set { self[.autoplayGIFs] = newValue.rawValue }
    }

    var autoplayVideos: Autoplay {
        get {
            if let rawValue = self[.autoplayVideos] as String?,
               let value = Autoplay(rawValue: rawValue) {
                return value
            }

            return .wifi
        }
        set { self[.autoplayVideos] = newValue.rawValue }
    }

    var homeTimelineBehavior: PositionBehavior {
        get {
            if let rawValue = self[.homeTimelineBehavior] as String?,
               let value = PositionBehavior(rawValue: rawValue) {
                return value
            }

            return .rememberPosition
        }
        set { self[.homeTimelineBehavior] = newValue.rawValue }
    }

    var notificationsTabBehavior: PositionBehavior {
        get {
            if let rawValue = self[.notificationsTabBehavior] as String?,
               let value = PositionBehavior(rawValue: rawValue) {
                return value
            }

            return .newest
        }
        set { self[.notificationsTabBehavior] = newValue.rawValue }
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

    var shouldReduceMotion: Bool {
        systemReduceMotion() && useSystemReduceMotionForMedia
    }

    func positionBehavior(markerTimeline: Marker.Timeline) -> PositionBehavior {
        switch markerTimeline {
        case .home:
            return homeTimelineBehavior
        case .notifications:
            return notificationsTabBehavior
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
}

private extension AppPreferences {
    enum Item: String {
        case statusWord
        case requireDoubleTapToReblog
        case requireDoubleTapToFavorite
        case useSystemReduceMotionForMedia
        case animateAvatars
        case animateHeaders
        case autoplayGIFs
        case autoplayVideos
        case homeTimelineBehavior
        case notificationsTabBehavior
        case defaultEmojiSkinTone
        case showReblogAndFavoriteCounts
    }

    subscript<T>(index: Item) -> T? {
        get { userDefaults.value(forKey: index.rawValue) as? T }
        set { userDefaults.set(newValue, forKey: index.rawValue) }
    }
}
