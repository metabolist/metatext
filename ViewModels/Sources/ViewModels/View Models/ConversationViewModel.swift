// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import Foundation
import Mastodon
import ServiceLayer

public final class ConversationViewModel: ObservableObject {
    public let accountViewModels: [AccountViewModel]
    public let statusViewModel: StatusViewModel?
    public let identityContext: IdentityContext

    private let conversationService: ConversationService

    init(conversationService: ConversationService, identityContext: IdentityContext) {
        accountViewModels = conversationService.conversation.accounts.map {
            AccountViewModel(
                accountService: conversationService.navigationService.accountService(account: $0),
                identityContext: identityContext,
                eventsSubject: .init())
        }

        if let status = conversationService.conversation.lastStatus {
            statusViewModel = StatusViewModel(
                statusService: conversationService.navigationService.statusService(status: status),
                identityContext: identityContext,
                eventsSubject: .init())
        } else {
            statusViewModel = nil
        }

        self.conversationService = conversationService
        self.identityContext = identityContext
    }
}

public extension ConversationViewModel {
    var isUnread: Bool { conversationService.conversation.unread }
}
