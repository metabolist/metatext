// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class RootViewModel: ObservableObject {
    @Published private(set) var tabNavigationViewModel: TabNavigationViewModel?
    @Published private var mostRecentlyUsedIdentityID: UUID?

    // swiftlint:disable weak_delegate
    private let appDelegate: AppDelegate
    // swiftlint:enable weak_delegate
    private let allIdentitiesService: AllIdentitiesService
    private let userNotificationService: UserNotificationService
    private var cancellables = Set<AnyCancellable>()

    init(appDelegate: AppDelegate,
         allIdentitiesService: AllIdentitiesService,
         userNotificationService: UserNotificationService) {
        self.appDelegate = appDelegate
        self.allIdentitiesService = allIdentitiesService
        self.userNotificationService = userNotificationService

        allIdentitiesService.mostRecentlyUsedIdentityID.assign(to: &$mostRecentlyUsedIdentityID)

        newIdentitySelected(id: mostRecentlyUsedIdentityID)

        userNotificationService.isAuthorized()
            .filter { $0 }
            .zip(appDelegate.registerForRemoteNotifications())
            .map { $1 }
            .flatMap(allIdentitiesService.updatePushSubscriptions(deviceToken:))
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}

extension RootViewModel {
    func newIdentitySelected(id: UUID?) {
        guard let id = id else {
            tabNavigationViewModel = nil

            return
        }

        let identityService: IdentityService

        do {
            identityService = try allIdentitiesService.identityService(id: id)
        } catch {
            return
        }

        identityService.observationErrors
            .receive(on: RunLoop.main)
            .map { [weak self] _ in self?.mostRecentlyUsedIdentityID }
            .sink { [weak self] in self?.newIdentitySelected(id: $0) }
            .store(in: &cancellables)

        identityService.updateLastUse()
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)

        userNotificationService.isAuthorized()
            .filter { $0 }
            .zip(appDelegate.registerForRemoteNotifications())
            .filter { identityService.identity.lastRegisteredDeviceToken != $1 }
            .map { ($1, identityService.identity.pushSubscriptionAlerts) }
            .flatMap(identityService.createPushSubscription(deviceToken:alerts:))
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)

        tabNavigationViewModel = TabNavigationViewModel(identityService: identityService)
    }

    func deleteIdentity(_ identity: Identity) {
        allIdentitiesService.deleteIdentity(identity)
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func addIdentityViewModel() -> AddIdentityViewModel {
        AddIdentityViewModel(allIdentitiesService: allIdentitiesService)
    }
}
