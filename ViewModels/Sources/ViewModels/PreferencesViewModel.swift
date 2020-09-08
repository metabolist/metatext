// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import ServiceLayer

public class PreferencesViewModel: ObservableObject {
    public let handle: String
    public let shouldShowNotificationTypePreferences: Bool

    private let identification: Identification

    public init(identification: Identification) {
        self.identification = identification
        handle = identification.identity.handle

        shouldShowNotificationTypePreferences = identification.identity.lastRegisteredDeviceToken != nil
    }
}
