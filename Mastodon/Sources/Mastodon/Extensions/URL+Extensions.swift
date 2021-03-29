// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

extension URL {
    init?(unicodeString: String) {
        if let url = Self(string: unicodeString) {
            self = url
        } else if let escaped = unicodeString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            let colonUnescaped = escaped.replacingOccurrences(
                of: "%3A",
                with: ":",
                range: escaped.range(of: "%3A"))

            if let url = URL(string: colonUnescaped) {
                self = url
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
