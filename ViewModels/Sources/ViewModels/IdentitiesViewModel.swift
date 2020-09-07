// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public class IdentitiesViewModel: ObservableObject {
    public let currentIdentityID: UUID
    @Published public var identities = [Identity]()
    @Published public var alertItem: AlertItem?

    private let environment: IdentifiedEnvironment
    private var cancellables = Set<AnyCancellable>()

    init(environment: IdentifiedEnvironment) {
        self.environment = environment
        currentIdentityID = environment.identity.id

        environment.identityService.identitiesObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$identities)
    }
}
