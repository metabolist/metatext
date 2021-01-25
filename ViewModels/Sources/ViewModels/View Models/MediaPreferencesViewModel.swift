// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class MediaPreferencesViewModel: ObservableObject {
    private let identification: Identification

    public init(identification: Identification) {
        self.identification = identification
    }
}
