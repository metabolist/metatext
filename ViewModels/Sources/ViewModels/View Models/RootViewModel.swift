// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class RootViewModel: ObservableObject {
    @Published public private(set) var navigationViewModel: NavigationViewModel?

    @Published private var mostRecentlyUsedIdentityId: Identity.Id?
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

        allIdentitiesService.immediateMostRecentlyUsedIdentityIdPublisher()
            .replaceError(with: nil)
            .assign(to: &$mostRecentlyUsedIdentityId)

        identitySelected(id: mostRecentlyUsedIdentityId, immediate: true)

        allIdentitiesService.identitiesCreated
            .sink { [weak self] in self?.identitySelected(id: $0) }
            .store(in: &cancellables)

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
    func identitySelected(id: Identity.Id?) {
        identitySelected(id: id, immediate: false)
    }

    func deleteIdentity(id: Identity.Id) {
        allIdentitiesService.deleteIdentity(id: id)
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func addIdentityViewModel() -> AddIdentityViewModel {
        AddIdentityViewModel(
            allIdentitiesService: allIdentitiesService,
            instanceURLService: InstanceURLService(environment: environment))
    }

    func newStatusViewModel(
        identityContext: IdentityContext,
        inReplyTo: StatusViewModel? = nil,
        redraft: Status? = nil) -> NewStatusViewModel {
        NewStatusViewModel(
            allIdentitiesService: allIdentitiesService,
            identityContext: identityContext,
            environment: environment,
            inReplyTo: inReplyTo,
            redraft: redraft,
            extensionContext: nil)
    }
}

private extension RootViewModel {
    func identitySelected(id: Identity.Id?, immediate: Bool) {
        navigationViewModel?.presentingSecondaryNavigation = false

        guard
            let id = id,
            let identityService = try? allIdentitiesService.identityService(id: id) else {
            navigationViewModel = nil

            return
        }

        let identityPublisher = identityService.identityPublisher(immediate: immediate)
            .catch { [weak self] _ -> Empty<Identity, Never> in
                DispatchQueue.main.async {
                    if self?.navigationViewModel?.identityContext.identity.id == id {
                        self?.identitySelected(id: self?.mostRecentlyUsedIdentityId, immediate: false)
                    }
                }

                return Empty()
            }
            .share()

        identityPublisher
            .first()
            .map { [weak self] in
                guard let self = self else { return nil }

                let identityContext = IdentityContext(
                    identity: $0,
                    publisher: identityPublisher.eraseToAnyPublisher(),
                    service: identityService,
                    environment: self.environment)

                identityContext.service.updateLastUse()
                    .sink { _ in } receiveValue: { _ in }
                    .store(in: &self.cancellables)

                self.userNotificationService.isAuthorized()
                    .filter { $0 }
                    .zip(self.registerForRemoteNotifications())
                    .filter { identityContext.identity.lastRegisteredDeviceToken != $1 }
                    .map { ($1, identityContext.identity.pushSubscriptionAlerts) }
                    .flatMap(identityContext.service.createPushSubscription(deviceToken:alerts:))
                    .sink { _ in } receiveValue: { _ in }
                    .store(in: &self.cancellables)

                return NavigationViewModel(identityContext: identityContext)
            }
            .assign(to: &$navigationViewModel)
    }
}
