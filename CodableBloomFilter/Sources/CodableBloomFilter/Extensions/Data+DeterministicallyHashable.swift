// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension Data: DeterministicallyHashable {
    public var deterministicallyHashableData: Data { self }
}
