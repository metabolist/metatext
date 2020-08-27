// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension Data {
    func hexEncodedString() -> String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}
