// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NotificationViewModel: CollectionItemViewModel, ObservableObject {
    public let accountViewModel: AccountViewModel
    public let statusViewModel: StatusViewModel?
    public let events: AnyPublisher<AnyPublisher<CollectionItemEvent, Error>, Never>
    public let identityContext: IdentityContext

    private let notificationService: NotificationService
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()

    init(notificationService: NotificationService, identityContext: IdentityContext) {
        self.notificationService = notificationService
        self.identityContext = identityContext
        self.accountViewModel = AccountViewModel(
            accountService: notificationService.navigationService.accountService(
                account: notificationService.notification.account),
            identityContext: identityContext)

        if let status = notificationService.notification.status {
            statusViewModel = StatusViewModel(
                statusService: notificationService.navigationService.statusService(status: status),
                identityContext: identityContext)
        } else {
            statusViewModel = nil
        }

        self.events = eventsSubject.eraseToAnyPublisher()
    }
}

public extension NotificationViewModel {
    var type: MastodonNotification.NotificationType {
        notificationService.notification.type
    }

    func accountSelected() {
        eventsSubject.send(
            Just(.navigation(
                    .profile(
                        notificationService.navigationService.profileService(
                            account: notificationService.notification.account))))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher())
    }
}
