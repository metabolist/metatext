// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Combine

class RootViewModel: ObservableObject {
    @Published private(set) var mainNavigationViewModel: MainNavigationViewModel?

    // swiftlint:disable weak_delegate
    private let appDelegate: AppDelegate
    // swiftlint:enable weak_delegate
    private let identitiesService: IdentitiesService
    private let userNotificationService: UserNotificationService
    private var cancellables = Set<AnyCancellable>()

    init(appDelegate: AppDelegate,
         identitiesService: IdentitiesService,
         userNotificationService: UserNotificationService) {
        self.appDelegate = appDelegate
        self.identitiesService = identitiesService
        self.userNotificationService = userNotificationService

        newIdentitySelected(id: identitiesService.mostRecentlyUsedIdentityID)

        userNotificationService.isAuthorized()
            .filter { $0 }
            .zip(appDelegate.registerForRemoteNotifications())
            .map { $1 }
            .flatMap(identitiesService.updatePushSubscriptions(deviceToken:))
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}

extension RootViewModel {
    func newIdentitySelected(id: UUID?) {
        guard let id = id else {
            mainNavigationViewModel = nil

            return
        }

        let identityService: IdentityService

        do {
            identityService = try identitiesService.identityService(id: id)
        } catch {
            return
        }

        identityService.observationErrors
            .receive(on: RunLoop.main)
            .map { [weak self] _ in self?.identitiesService.mostRecentlyUsedIdentityID }
            .sink(receiveValue: newIdentitySelected(id:))
            .store(in: &cancellables)

        identityService.updateLastUse()
            .sink(receiveCompletion: { _ in }, receiveValue: {})
            .store(in: &cancellables)

        mainNavigationViewModel = MainNavigationViewModel(identityService: identityService)
    }

    func newIdentityCreated(id: UUID, instanceURL: URL) {
        newIdentitySelected(id: id)

        userNotificationService.isAuthorized()
            .filter { $0 }
            .zip(appDelegate.registerForRemoteNotifications())
            .map { (id, instanceURL, $1, nil) }
            .flatMap(identitiesService.updatePushSubscription(identityID:instanceURL:deviceToken:alerts:))
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func deleteIdentity(id: UUID) {
        identitiesService.deleteIdentity(id: id)
            .sink(receiveCompletion: { _ in }, receiveValue: {})
            .store(in: &cancellables)
    }

    func addIdentityViewModel() -> AddIdentityViewModel {
        AddIdentityViewModel(identitiesService: identitiesService)
    }
}
