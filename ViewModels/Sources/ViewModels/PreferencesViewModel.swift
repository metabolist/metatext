// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import ServiceLayer

public class PreferencesViewModel: ObservableObject {
    public let handle: String
    public let shouldShowNotificationTypePreferences: Bool

    private let environment: IdentifiedEnvironment

    init(environment: IdentifiedEnvironment) {
        self.environment = environment
        handle = environment.identity.handle

        shouldShowNotificationTypePreferences = environment.identity.lastRegisteredDeviceToken != nil
    }
}

public extension PreferencesViewModel {
    func postingReadingPreferencesViewModel() -> PostingReadingPreferencesViewModel {
        PostingReadingPreferencesViewModel(environment: environment)
    }

    func notificationTypesPreferencesViewModel() -> NotificationTypesPreferencesViewModel {
        NotificationTypesPreferencesViewModel(environment: environment)
    }

    func filtersViewModel() -> FiltersViewModel {
        FiltersViewModel(environment: environment)
    }
}
