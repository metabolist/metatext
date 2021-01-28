// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class IdentitiesViewModel: ObservableObject {
    @Published public private(set) var identities = [Identity]()
    @Published public var alertItem: AlertItem?
    public let identityContext: IdentityContext

    private var cancellables = Set<AnyCancellable>()

    public init(identityContext: IdentityContext) {
        self.identityContext = identityContext

        identityContext.service.identitiesPublisher()
            .receive(on: RunLoop.main)
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .assign(to: &$identities)
    }
}

public extension IdentitiesViewModel {
    func viewModel(identity: Identity) -> IdentityViewModel {
        .init(identity: identity, identityContext: identityContext)
    }
}
