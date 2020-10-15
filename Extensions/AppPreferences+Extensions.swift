// Copyright © 2020 Metabolist. All rights reserved.

import UIKit
import ViewModels

extension AppPreferences {
    var shouldReduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled && useSystemReduceMotionForMedia
    }
}
