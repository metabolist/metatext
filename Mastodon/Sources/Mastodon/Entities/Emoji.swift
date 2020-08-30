// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Emoji: Codable, Hashable {
    public let shortcode: String
    public let staticUrl: URL
    public let url: URL
    public let visibleInPicker: Bool
}
