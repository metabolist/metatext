// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct Identity: Codable, Hashable {
    let id: String
    let url: URL
    let instance: Identity.Instance?
    let account: Identity.Account?
}

extension Identity {
    struct Instance: Codable, Hashable {
        let uri: String
        let streamingAPI: URL
        let title: String
        let thumbnail: URL?
    }

    struct Account: Codable, Hashable {
        let id: String
        let identityID: String
        let username: String
        let url: URL
        let avatar: URL
        let avatarStatic: URL
        let header: URL
        let headerStatic: URL
    }
}

extension Identity {
    var handle: String {
        if let account = account, let host = account.url.host {
            return account.url.lastPathComponent + "@" + host
        }

        return instance?.title ?? url.host ?? url.absoluteString
    }
}