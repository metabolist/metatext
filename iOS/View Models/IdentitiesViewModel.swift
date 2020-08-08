// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

class IdentitiesViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    @Published var identities = [Identity]()
    @Published var alertItem: AlertItem?

    private let identityRepository: IdentityRepository
    private var cancellables = Set<AnyCancellable>()

    init(identityRepository: IdentityRepository) {
        self.identityRepository = identityRepository
        identity = identityRepository.identity

        identityRepository.identitiesObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$identities)
    }
}
