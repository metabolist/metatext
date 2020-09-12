// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension URL: Identifiable {
    public var id: String { absoluteString }
}
