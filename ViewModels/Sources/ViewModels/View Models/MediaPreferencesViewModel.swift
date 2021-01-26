// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class MediaPreferencesViewModel: ObservableObject {
    public let identityContext: IdentityContext

    public init(identityContext: IdentityContext) {
        self.identityContext = identityContext
    }
}
