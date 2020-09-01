// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public class IdentitiesViewModel: ObservableObject {
    @Published public private(set) var identity: Identity
    @Published public var identities = [Identity]()
    @Published public var alertItem: AlertItem?

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
