// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import ServiceLayer

public final class RootViewModel: ObservableObject {
    @Published public private(set) var identification: Identification?

    @Published private var mostRecentlyUsedIdentityID: UUID?
    private let environment: AppEnvironment
    private let allIdentitiesService: AllIdentitiesService
    private let userNotificationService: UserNotificationService
    private let registerForRemoteNotifications: () -> AnyPublisher<Data, Error>
    private var cancellables = Set<AnyCancellable>()

    public init(environment: AppEnvironment,
                registerForRemoteNotifications: @escaping () -> AnyPublisher<Data, Error>) throws {
        self.environment = environment
        allIdentitiesService = try AllIdentitiesService(environment: environment)
        userNotificationService = UserNotificationService(environment: environment)
        self.registerForRemoteNotifications = registerForRemoteNotifications

        allIdentitiesService.mostRecentlyUsedIdentityID.assign(to: &$mostRecentlyUsedIdentityID)

        newIdentitySelected(id: mostRecentlyUsedIdentityID)

        userNotificationService.isAuthorized()
            .filter { $0 }
            .zip(registerForRemoteNotifications())
            .map { $1 }
            .flatMap(allIdentitiesService.updatePushSubscriptions(deviceToken:))
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}

public extension RootViewModel {
    func newIdentitySelected(id: UUID?) {
        guard let id = id else {
            identification = nil

            return
        }

        let identification: Identification

        do {
            identification = try Identification(service: allIdentitiesService.identityService(id: id))
            self.identification = identification
        } catch {
            return
        }

        identification.observationErrors
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.newIdentitySelected(id: self?.mostRecentlyUsedIdentityID ) }
            .store(in: &cancellables)

        identification.service.updateLastUse()
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)

        userNotificationService.isAuthorized()
            .filter { $0 }
            .zip(registerForRemoteNotifications())
            .filter { identification.identity.lastRegisteredDeviceToken != $1 }
            .map { ($1, identification.identity.pushSubscriptionAlerts) }
            .flatMap(identification.service.createPushSubscription(deviceToken:alerts:))
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func deleteIdentity(id: UUID) {
        allIdentitiesService.deleteIdentity(id: id)
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func addIdentityViewModel() -> AddIdentityViewModel {
        AddIdentityViewModel(
            allIdentitiesService: allIdentitiesService,
            instanceFilterService: InstanceFilterService(environment: environment))
    }
}
