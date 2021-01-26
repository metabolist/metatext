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
    private let identityContext: IdentityContext
    private let eventsSubject = PassthroughSubject<AnyPublisher<CollectionItemEvent, Error>, Never>()

    init(conversationService: ConversationService, identityContext: IdentityContext) {
        accountViewModels = conversationService.conversation.accounts.map {
            AccountViewModel(
                accountService: conversationService.navigationService.accountService(account: $0),
                identityContext: identityContext)
        }

        if let status = conversationService.conversation.lastStatus {
            statusViewModel = StatusViewModel(
                statusService: conversationService.navigationService.statusService(status: status),
                identityContext: identityContext)
        } else {
            statusViewModel = nil
        }

        self.conversationService = conversationService
        self.identityContext = identityContext
        self.events = eventsSubject.eraseToAnyPublisher()
    }
}
