// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

class IdentitiesViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    @Published var identities = [Identity]()
    @Published var alertItem: AlertItem?

    private let environment: IdentifiedEnvironment
    private var cancellables = Set<AnyCancellable>()

    init(environment: IdentifiedEnvironment) {
        self.environment = environment
        identity = environment.identity

        environment.appEnvironment.identityDatabase.identitiesObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$identities)
    }
}
