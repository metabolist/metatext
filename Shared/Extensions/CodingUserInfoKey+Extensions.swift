// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

typealias AttributedStringCache = NSCache<NSString, NSAttributedString>

extension CodingUserInfoKey {
    static let attributedStringCache = CodingUserInfoKey(rawValue: "com.metabolist.metatext.attributed-string-cache")!
}
