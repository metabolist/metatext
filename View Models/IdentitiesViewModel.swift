// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation

class IdentitiesViewModel: ObservableObject {
    @Published private(set) var identity: Identity
    @Published var identities = [Identity]()
    @Published var alertItem: AlertItem?

    private let identityService: IdentityService
    private var cancellables = Set<AnyCancellable>()

    init(identityService: IdentityService) {
        self.identityService = identityService
        identity = identityService.identity

        identityService.identitiesObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$identities)
    }
}
