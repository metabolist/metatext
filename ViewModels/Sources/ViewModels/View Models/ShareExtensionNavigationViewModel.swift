// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public enum ShareExtensionError: Error {
    case noAccountFound
}

public final class ShareExtensionNavigationViewModel: ObservableObject {
    @Published public var alertItem: AlertItem?

    private let environment: AppEnvironment

    public init(environment: AppEnvironment) {
        self.environment = environment
    }
}

public extension ShareExtensionNavigationViewModel {
    func newStatusViewModel(extensionContext: NSExtensionContext?) throws -> NewStatusViewModel {
        let allIdentitiesService = try AllIdentitiesService(environment: environment)

        guard let identity = try allIdentitiesService.mostRecentAuthenticatedIdentity()
        else { throw ShareExtensionError.noAccountFound }

        let identityService = try allIdentitiesService.identityService(id: identity.id)
        let identityContext = IdentityContext(
            identity: identity,
            publisher: identityService.identityPublisher(immediate: false)
                .assignErrorsToAlertItem(to: \.alertItem, on: self),
            service: identityService,
            environment: environment)

        return NewStatusViewModel(
            allIdentitiesService: allIdentitiesService,
            identityContext: identityContext,
            environment: environment,
            identity: nil,
            inReplyTo: nil,
            redraft: nil,
            directMessageTo: nil,
            extensionContext: extensionContext)
    }
}
