// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NotificationViewModel: CollectionItemViewModel, ObservableObject {
    public let accountViewModel: AccountViewModel
    public let statusViewModel: StatusViewModel?
    public let events: AnyPublisher<AnyPublisher<CollectionItemEvent, Error>, Never>

    private let notificationService: NotificationService
    private let identification: Identification
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()

    init(notificationService: NotificationService, identification: Identification) {
        self.notificationService = notificationService
        self.identification = identification
        self.accountViewModel = AccountViewModel(
            accountService: notificationService.navigationService.accountService(
                account: notificationService.notification.account),
            identification: identification)

        if let status = notificationService.notification.status {
            statusViewModel = StatusViewModel(
                statusService: notificationService.navigationService.statusService(status: status),
                identification: identification)
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
