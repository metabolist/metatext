// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

public struct Announcement: Codable, Hashable {
    public let id: Id
    public let content: HTML
    public let startsAt: Date?
    public let endsAt: Date?
    public let allDay: Bool
    public let publishedAt: Date
    public let updatedAt: Date
    public let read: Bool
    public let mentions: [Mention]
    public let tags: [Tag]
    public let emojis: [Emoji]
    public let reactions: [AnnouncementReaction]
}

public extension Announcement {
    typealias Id = String
}
