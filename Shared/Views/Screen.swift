// Copyright © 2020 Metabolist. All rights reserved.

import SwiftUI

struct Screen {
    static var scale: CGFloat {
        #if os(macOS)
        return NSScreen.main?.backingScaleFactor ?? 1
        #else
        return UIScreen.main.scale
        #endif
    }
}
