// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import ServiceLayer

class PreferencesViewModel: ObservableObject {
    let handle: String
    let shouldShowNotificationTypePreferences: Bool

    private let identityService: IdentityService

    init(identityService: IdentityService) {
        self.identityService = identityService
        handle = identityService.identity.handle

        shouldShowNotificationTypePreferences = identityService.identity.lastRegisteredDeviceToken != nil
    }
}

extension PreferencesViewModel {
    func postingReadingPreferencesViewModel() -> PostingReadingPreferencesViewModel {
        PostingReadingPreferencesViewModel(identityService: identityService)
    }

    func notificationTypesPreferencesViewModel() -> NotificationTypesPreferencesViewModel {
        NotificationTypesPreferencesViewModel(identityService: identityService)
    }

    func filtersViewModel() -> FiltersViewModel {
        FiltersViewModel(identityService: identityService)
    }
}
