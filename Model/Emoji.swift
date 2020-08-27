// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct Emoji: Codable, Hashable {
    let shortcode: String
    let staticUrl: URL
    let url: URL
    let visibleInPicker: Bool
}
