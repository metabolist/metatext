// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct Status {
    enum Visibility: String, Codable, Unknowable {
        case `public`
        case unlisted
        case `private`
        case direct
        case unknown

        static var unknownCase: Self { .unknown }
    }
}
