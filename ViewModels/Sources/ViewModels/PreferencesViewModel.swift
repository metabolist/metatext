// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import ServiceLayer

public final class PreferencesViewModel: ObservableObject {
    public let handle: String
    public let shouldShowNotificationTypePreferences: Bool

    private let identification: Identification

    public init(identification: Identification) {
        self.identification = identification
        handle = identification.identity.handle

        shouldShowNotificationTypePreferences = identification.identity.lastRegisteredDeviceToken != nil
    }
}

public extension PreferencesViewModel {
    func mutedUsersViewModel() -> CollectionViewModel {
        CollectionItemsViewModel(
            collectionService: identification.service.service(accountList: .mutes),
            identification: identification)
    }

    func blockedUsersViewModel() -> CollectionViewModel {
        CollectionItemsViewModel(
            collectionService: identification.service.service(accountList: .blocks),
            identification: identification)
    }

    func domainBlocksViewModel() -> DomainBlocksViewModel {
        DomainBlocksViewModel(service: identification.service.domainBlocksService())
    }
}
