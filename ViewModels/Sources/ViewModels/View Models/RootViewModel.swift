// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class RootViewModel: ObservableObject {
    @Published public private(set) var navigationViewModel: NavigationViewModel?

    @Published private var mostRecentlyUsedIdentityId: Identity.Id?
    private let environment: AppEnvironment
    private let registerForRemoteNotifications: () -> AnyPublisher<Data, Error>
    private let allIdentitiesService: AllIdentitiesService
    private let userNotificationService: UserNotificationService
    private var cancellables = Set<AnyCancellable>()

    public init(environment: AppEnvironment,
                registerForRemoteNotifications: @escaping () -> AnyPublisher<Data, Error>) throws {
        self.environment = environment
        self.registerForRemoteNotifications = registerForRemoteNotifications
        allIdentitiesService = try AllIdentitiesService(environment: environment)
        userNotificationService = UserNotificationService(environment: environment)

        allIdentitiesService.immediateMostRecentlyUsedIdentityIdPublisher()
            .replaceError(with: nil)
            .assign(to: &$mostRecentlyUsedIdentityId)

        identitySelected(id: mostRecentlyUsedIdentityId, immediate: true, notify: false)

        allIdentitiesService.identitiesCreated
            .sink { [weak self] in self?.identitySelected(id: $0) }
            .store(in: &cancellables)

        userNotificationService.isAuthorized(request: false)
            .filter { $0 }
            .zip(registerForRemoteNotifications())
            .map { $1 }
            .flatMap(allIdentitiesService.updatePushSubscriptions(deviceToken:))
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)

        userNotificationService.events
            .sink { [weak self] in self?.handle(event: $0) }
            .store(in: &cancellables)
    }
}

public extension RootViewModel {
    func identitySelected(id: Identity.Id?) {
        identitySelected(id: id, immediate: false, notify: false)
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
        identity: Identity? = nil,
        inReplyTo: StatusViewModel? = nil,
        redraft: Status? = nil,
        directMessageTo: AccountViewModel? = nil) -> NewStatusViewModel {
        NewStatusViewModel(
            allIdentitiesService: allIdentitiesService,
            identityContext: identityContext,
            environment: environment,
            identity: identity,
            inReplyTo: inReplyTo,
            redraft: redraft,
            directMessageTo: directMessageTo,
            extensionContext: nil)
    }
}

private extension RootViewModel {
    static let identityChangeNotificationUserInfoKey =
        "com.metabolist.metatext.identity-change-notification-user-info-key"
    static let removeIdentityChangeNotificationAfter = DispatchTimeInterval.seconds(10)

    // swiftlint:disable:next function_body_length
    func identitySelected(id: Identity.Id?, immediate: Bool, notify: Bool) {
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
                        self?.identitySelected(id: self?.mostRecentlyUsedIdentityId,
                                               immediate: false,
                                               notify: true)
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

                if identityContext.identity.authenticated,
                   !identityContext.identity.pending {
                    self.userNotificationService.isAuthorized(request: true)
                        .filter { $0 }
                        .zip(self.registerForRemoteNotifications())
                        .filter { identityContext.identity.lastRegisteredDeviceToken != $1 }
                        .map { ($1, identityContext.identity.pushSubscriptionAlerts) }
                        .flatMap(identityContext.service.createPushSubscription(deviceToken:alerts:))
                        .sink { _ in } receiveValue: { _ in }
                        .store(in: &self.cancellables)
                }

                if notify {
                    self.notifyIdentityChange(identityContext: identityContext)
                }

                return NavigationViewModel(identityContext: identityContext)
            }
            .assign(to: &$navigationViewModel)
    }

    func handle(event: UserNotificationService.Event) {
        switch event {
        case let .willPresentNotification(notification, completionHandler):
            completionHandler(.banner)

            if notification.request.content.userInfo[Self.identityChangeNotificationUserInfoKey] as? Bool == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.removeIdentityChangeNotificationAfter) {
                    self.userNotificationService.removeDeliveredNotifications(
                        withIdentifiers: [notification.request.identifier])
                }
            }
        case let .didReceiveResponse(response, completionHandler):
            let userInfo = response.notification.request.content.userInfo

            if let identityIdString = userInfo[PushNotificationParsingService.identityIdUserInfoKey] as? String,
               let identityId = Identity.Id(uuidString: identityIdString),
               let pushNotificationJSON = userInfo[PushNotificationParsingService.pushNotificationUserInfoKey] as? Data,
               let pushNotification = try? MastodonDecoder().decode(PushNotification.self, from: pushNotificationJSON) {
                handle(pushNotification: pushNotification, identityId: identityId)
            }

            completionHandler()
        default:
            break
        }
    }

    func handle(pushNotification: PushNotification, identityId: Identity.Id) {
        if identityId != navigationViewModel?.identityContext.identity.id {
            identitySelected(id: identityId, immediate: false, notify: true)
        }

        $navigationViewModel.first { $0?.identityContext.identity.id == identityId }
            // Ensure views are set up if switching accounts
            .delay(for: .milliseconds(1), scheduler: DispatchQueue.main)
            .sink { $0?.navigate(pushNotification: pushNotification) }
            .store(in: &cancellables)
    }

    func notifyIdentityChange(identityContext: IdentityContext) {
        let content = UserNotificationService.MutableContent()

        content.body = String.localizedStringWithFormat(
            NSLocalizedString("notification.signed-in-as-%@", comment: ""),
            identityContext.identity.handle)
        content.userInfo[Self.identityChangeNotificationUserInfoKey] = true

        let request = UserNotificationService.Request(identifier: UUID().uuidString, content: content, trigger: nil)

        userNotificationService.add(request: request)
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
