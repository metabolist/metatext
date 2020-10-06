// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class Identification: ObservableObject {
    @Published private(set) public var identity: Identity
    let service: IdentityService

    init(identity: Identity, publisher: AnyPublisher<Identity, Never>, service: IdentityService) {
        self.identity = identity
        self.service = service

        DispatchQueue.main.async {
            publisher.dropFirst().assign(to: &self.$identity)
        }
    }
}
