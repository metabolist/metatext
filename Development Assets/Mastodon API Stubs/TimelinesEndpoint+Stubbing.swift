// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension TimelinesEndpoint: Stubbing {
    func data(url: URL) -> Data? {
        NSDataAsset(name: "TimelineJSON")!.data
    }
}
