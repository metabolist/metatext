// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum NavigationEvent {
    case collectionNavigation(CollectionViewModel)
    case urlNavigation(URL)
    case share(URL)
}
