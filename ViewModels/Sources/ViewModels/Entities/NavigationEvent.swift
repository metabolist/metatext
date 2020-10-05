// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public enum NavigationEvent {
    case collectionNavigation(CollectionViewModel)
    case profileNavigation(ProfileViewModel)
    case urlNavigation(URL)
    case share(URL)
    case webfingerStart
    case webfingerEnd
}

extension NavigationEvent {
    public init?(_ event: CollectionItemEvent) {
        switch event {
        case .ignorableOutput:
            return nil
        case let .navigation(item):
            switch item {
            case let .url(url):
                self = .urlNavigation(url)
            case let .collection(statusListService):
                self = .collectionNavigation(ListViewModel(collectionService: statusListService))
            case let .profile(profileService):
                self = .profileNavigation(ProfileViewModel(profileService: profileService))
            case .webfingerStart:
                self = .webfingerStart
            case .webfingerEnd:
                self = .webfingerEnd
            }
        case let .share(url):
            self = .share(url)
        }
    }
}
