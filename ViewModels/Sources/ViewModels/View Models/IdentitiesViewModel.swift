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
    public let identityContext: IdentityContext

    private var cancellables = Set<AnyCancellable>()

    public init(identityContext: IdentityContext) {
        self.identityContext = identityContext
        currentIdentityId = identityContext.identity.id

        let identitiesPublisher = identityContext.service.identitiesPublisher()
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .share()

        identitiesPublisher.map { $0.filter { $0.authenticated && !$0.pending } }
            .assign(to: &$authenticated)
        identitiesPublisher.map { $0.filter { !$0.authenticated && !$0.pending } }
            .assign(to: &$unauthenticated)
        identitiesPublisher.map { $0.filter { $0.pending } }
            .assign(to: &$pending)
    }
}
