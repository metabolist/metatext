// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import UIKit
import ViewModels

extension NavigationViewModel.Tab {
    var title: String {
        switch self {
        case .timelines:
            return NSLocalizedString("main-navigation.timelines", comment: "")
        case .explore:
            return NSLocalizedString("main-navigation.explore", comment: "")
        case .notifications:
            return NSLocalizedString("main-navigation.notifications", comment: "")
        case .messages:
            return NSLocalizedString("main-navigation.conversations", comment: "")
        }
    }

    var systemImageName: String {
        switch self {
        case .timelines: return "newspaper"
        case .explore: return "magnifyingglass"
        case .notifications: return "bell"
        case .messages: return "envelope"
        }
    }

    var tabBarItem: UITabBarItem {
        UITabBarItem(title: title, image: UIImage(systemName: systemImageName), selectedImage: nil)
    }
}
