// Copyright © 2021 Metabolist. All rights reserved.

import Foundation
import Mastodon
import ServiceLayer

public final class InstanceViewModel: ObservableObject {
    private let instanceService: InstanceService

    init(instanceService: InstanceService) {
        self.instanceService = instanceService
    }
}

public extension InstanceViewModel {
    var instance: Instance { instanceService.instance }
}
