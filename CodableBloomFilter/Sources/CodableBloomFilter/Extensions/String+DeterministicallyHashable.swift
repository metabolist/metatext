// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension String: DeterministicallyHashable {
    public var deterministicallyHashableData: Data { Data(utf8) }
}
