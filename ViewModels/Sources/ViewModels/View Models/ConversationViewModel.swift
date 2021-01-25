// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class ConversationViewModel: CollectionItemViewModel, ObservableObject {
    public let accountViewModels: [AccountViewModel]
    public let statusViewModel: StatusViewModel?
    public let events: AnyPublisher<AnyPublisher<CollectionItemEvent, Error>, Never>

    private let conversationService: ConversationService
    private let identification: Identification
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()

    init(conversationService: ConversationService, identification: Identification) {
        accountViewModels = conversationService.conversation.accounts.map {
            AccountViewModel(
                accountService: conversationService.navigationService.accountService(account: $0),
                identification: identification)
        }

        if let status = conversationService.conversation.lastStatus {
            statusViewModel = StatusViewModel(
                statusService: conversationService.navigationService.statusService(status: status),
                identification: identification)
        } else {
            statusViewModel = nil
        }

        self.conversationService = conversationService
        self.identification = identification
        self.events = eventsSubject.eraseToAnyPublisher()
    }
}
