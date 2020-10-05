// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class IdentitiesViewModel: ObservableObject {
    public let currentIdentityId: Identity.Id
    @Published public var authenticated = [Identity]()
    @Published public var unauthenticated = [Identity]()
    @Published public var pending = [Identity]()
    @Published public var alertItem: AlertItem?

    private let identification: Identification
    private var cancellables = Set<AnyCancellable>()

    public init(identification: Identification) {
        self.identification = identification
        currentIdentityId = identification.identity.id

        let observation = identification.service.identitiesObservation()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .share()

        observation.map { $0.filter { $0.authenticated && !$0.pending } }
            .assign(to: &$authenticated)
        observation.map { $0.filter { !$0.authenticated && !$0.pending } }
            .assign(to: &$unauthenticated)
        observation.map { $0.filter { $0.pending } }
            .assign(to: &$pending)
    }
}
