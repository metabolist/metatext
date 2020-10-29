// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct ConversationService {
    public let conversation: Conversation
    public let navigationService: NavigationService
    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase

    init(conversation: Conversation, mastodonAPIClient: MastodonAPIClient, contentDatabase: ContentDatabase) {
        self.conversation = conversation
        self.navigationService = NavigationService(
            mastodonAPIClient: mastodonAPIClient,
            contentDatabase: contentDatabase)
        self.mastodonAPIClient = mastodonAPIClient
        self.contentDatabase = contentDatabase
    }
}
