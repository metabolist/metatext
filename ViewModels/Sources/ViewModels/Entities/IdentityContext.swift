// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class IdentityContext: ObservableObject {
    @Published private(set) public var identity: Identity
    @Published private(set) public var authenticatedOtherIdentities = [Identity]()
    @Published public var appPreferences: AppPreferences
    let service: IdentityService

    init(identity: Identity,
         publisher: AnyPublisher<Identity, Never>,
         service: IdentityService,
         environment: AppEnvironment) {
        self.identity = identity
        self.service = service
        appPreferences = AppPreferences(environment: environment)

        DispatchQueue.main.async {
            publisher.dropFirst().assign(to: &self.$identity)
            service.otherAuthenticatedIdentitiesPublisher()
                .replaceError(with: [])
                .assign(to: &self.$authenticatedOtherIdentities)
        }
    }
}
