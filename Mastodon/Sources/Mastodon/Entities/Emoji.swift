// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Emoji: Codable, Hashable {
    public let shortcode: String
    public let staticUrl: String?
    public let url: String?
    public let visibleInPicker: Bool
    public let category: String?
}
