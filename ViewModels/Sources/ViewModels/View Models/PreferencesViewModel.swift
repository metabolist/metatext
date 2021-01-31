// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class PreferencesViewModel: ObservableObject {
    @Published public var preferences: Identity.Preferences
    @Published public var alertItem: AlertItem?
    public let shouldShowNotificationTypePreferences: Bool
    public let identityContext: IdentityContext

    private var cancellables = Set<AnyCancellable>()

    public init(identityContext: IdentityContext) {
        self.identityContext = identityContext

        shouldShowNotificationTypePreferences = identityContext.identity.lastRegisteredDeviceToken != nil
        preferences = identityContext.identity.preferences

        identityContext.$identity
            .map(\.preferences)
            .dropFirst()
            .removeDuplicates()
            .assign(to: &$preferences)

        $preferences
            .dropFirst()
            .flatMap {
                identityContext.service.updatePreferences(
                    $0,
                    authenticated: identityContext.identity.authenticated)
            }
            .assignErrorsToAlertItem(to: \.alertItem, on: self)
            .sink { _ in }
            .store(in: &cancellables)
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
