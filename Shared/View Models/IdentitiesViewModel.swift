// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

class IdentitiesViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    @Published var identities = [Identity]()
    @Published var alertItem: AlertItem?

    private let environment: AppEnvironment
    private var cancellables = Set<AnyCancellable>()

    init(identity: Published<Identity>, environment: AppEnvironment) {
        _identity = identity
        self.environment = environment

        environment.identityDatabase.identitiesObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$identities)
    }
}

extension IdentitiesViewModel {
    func identitySelected(id: String) {
        environment.identityDatabase.updateLastUsedAt(identityID: id)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }
}
