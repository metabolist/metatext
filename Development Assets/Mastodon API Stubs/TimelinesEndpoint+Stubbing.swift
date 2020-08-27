// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import UIKit

extension TimelinesEndpoint: Stubbing {
    func data(url: URL) -> Data? {
        NSDataAsset(name: "timelineJSON")!.data
    }
}
