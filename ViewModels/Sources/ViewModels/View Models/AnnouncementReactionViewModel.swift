// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import Mastodon

public struct AnnouncementReactionViewModel {
    let identityContext: IdentityContext

    private let announcementReaction: AnnouncementReaction

    public init(announcementReaction: AnnouncementReaction, identityContext: IdentityContext) {
        self.announcementReaction = announcementReaction
        self.identityContext = identityContext
    }
}

public extension AnnouncementReactionViewModel {
    var name: String { announcementReaction.name }

    var count: Int { announcementReaction.count }

    var me: Bool { announcementReaction.me }

    var url: URL? {
        if identityContext.appPreferences.animateCustomEmojis {
            return announcementReaction.url?.url
        } else {
            return announcementReaction.staticUrl?.url
        }
    }
}
