// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import ServiceLayer

public final class PreferencesViewModel: ObservableObject {
    public let handle: String
    public let shouldShowNotificationTypePreferences: Bool

    private let identityContext: IdentityContext

    public init(identityContext: IdentityContext) {
        self.identityContext = identityContext
        handle = identityContext.identity.handle

        shouldShowNotificationTypePreferences = identityContext.identity.lastRegisteredDeviceToken != nil
    }
}

public extension PreferencesViewModel {
    func mutedUsersViewModel() -> CollectionViewModel {
        CollectionItemsViewModel(
            collectionService: identityContext.service.service(accountList: .mutes),
            identityContext: identityContext)
    }

    func blockedUsersViewModel() -> CollectionViewModel {
        CollectionItemsViewModel(
            collectionService: identityContext.service.service(accountList: .blocks),
            identityContext: identityContext)
    }

    func domainBlocksViewModel() -> DomainBlocksViewModel {
        DomainBlocksViewModel(service: identityContext.service.domainBlocksService())
    }
}
