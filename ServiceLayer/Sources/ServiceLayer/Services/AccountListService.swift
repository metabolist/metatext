// Copyright © 2020 Metabolist. All rights reserved.

import Combine
import DB
import Foundation
import Mastodon
import MastodonAPI

public struct AccountListService {
    public let accountSections: AnyPublisher<[[Account]], Error>
    public let paginates: Bool

    private let mastodonAPIClient: MastodonAPIClient
    private let contentDatabase: ContentDatabase
    private let requestClosure: (_ maxID: String?, _ minID: String?) -> AnyPublisher<Never, Error>
}

extension AccountListService {

}

public extension AccountListService {
    func request(maxID: String?, minID: String?) -> AnyPublisher<Never, Error> {
        requestClosure(maxID, minID)
    }
}
