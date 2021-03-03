// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import HTTP
import Mastodon

public enum EmptyEndpoint {
    case oauthRevoke(token: String, clientId: String, clientSecret: String)
    case addAccountsToList(id: List.Id, accountIds: Set<Account.Id>)
    case removeAccountsFromList(id: List.Id, accountIds: Set<Account.Id>)
    case deleteList(id: List.Id)
    case deleteFilter(id: Filter.Id)
    case blockDomain(String)
    case unblockDomain(String)
}

extension EmptyEndpoint: Endpoint {
    public typealias ResultType = [String: String]

    public var context: [String] {
        switch self {
        case .oauthRevoke:
            return ["oauth"]
        case .addAccountsToList, .removeAccountsFromList, .deleteList:
            return defaultContext + ["lists"]
        case .deleteFilter:
            return defaultContext + ["filters"]
        case .blockDomain, .unblockDomain:
            return defaultContext + ["domain_blocks"]
        }
    }

    public var pathComponentsInContext: [String] {
        switch self {
        case .oauthRevoke:
            return ["revoke"]
        case let .addAccountsToList(id, _), let .removeAccountsFromList(id, _):
            return [id, "accounts"]
        case let .deleteList(id), let .deleteFilter(id):
            return [id]
        case .blockDomain, .unblockDomain:
            return []
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .addAccountsToList, .oauthRevoke, .blockDomain:
            return .post
        case .removeAccountsFromList, .deleteList, .deleteFilter, .unblockDomain:
            return .delete
        }
    }

    public var jsonBody: [String: Any]? {
        switch self {
        case let .oauthRevoke(token, clientId, clientSecret):
            return ["token": token, "client_id": clientId, "client_secret": clientSecret]
        case let .addAccountsToList(_, accountIds), let .removeAccountsFromList(_, accountIds):
            return ["account_ids": Array(accountIds)]
        case let .blockDomain(domain), let .unblockDomain(domain):
            return ["domain": domain]
        case .deleteList, .deleteFilter:
            return nil
        }
    }
}
