// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NotificationViewModel: ObservableObject {
    public let accountViewModel: AccountViewModel
    public let statusViewModel: StatusViewModel?
    public let identityContext: IdentityContext

    private let notificationService: NotificationService
    private let eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>

    init(notificationService: NotificationService,
         identityContext: IdentityContext,
         eventsSubject: PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>) {
        self.notificationService = notificationService
        self.identityContext = identityContext
        self.eventsSubject = eventsSubject
        self.accountViewModel = AccountViewModel(
            accountService: notificationService.navigationService.accountService(
                account: notificationService.notification.account),
            identityContext: identityContext,
            eventsSubject: eventsSubject)

        if let status = notificationService.notification.status {
            statusViewModel = StatusViewModel(
                statusService: notificationService.navigationService.statusService(status: status),
                identityContext: identityContext,
                eventsSubject: eventsSubject)
        } else {
            statusViewModel = nil
        }
    }
}

public extension NotificationViewModel {
    var type: MastodonNotification.NotificationType {
        notificationService.notification.type
    }

    var time: String? { notificationService.notification.createdAt.timeAgo }

    var accessibilityTime: String? {
        notificationService.notification.createdAt.accessibilityTimeAgo
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
