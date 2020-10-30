// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class NotificationViewModel: CollectionItemViewModel, ObservableObject {
    public let accountViewModel: AccountViewModel
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
        self.events = eventsSubject.eraseToAnyPublisher()
    }
}

public extension NotificationViewModel {
    var type: MastodonNotification.NotificationType {
        notificationService.notification.type
    }
}
