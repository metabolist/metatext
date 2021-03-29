// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

public struct AnnouncementReaction: Codable, Hashable {
    public let name: String
    public let count: Int
    public let me: Bool
    public let url: UnicodeURL?
    public let staticUrl: UnicodeURL?
}
