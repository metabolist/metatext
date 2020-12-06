// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NewStatusViewModel: ObservableObject {
    private let service: NewStatusService

    public init(service: NewStatusService) {
        self.service = service
    }
}
