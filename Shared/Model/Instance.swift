// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

struct Instance: Codable, Hashable {
    struct URLs: Codable, Hashable {
        let streamingApi: URL
    }

    struct Stats: Codable, Hashable {
        let userCount: Int
        let statusCount: Int
        let domainCount: Int
    }

    let uri: String
    let title: String
    let description: String
    let shortDescription: String?
    let email: String
    let version: String
    let languages: [String]
    let registrations: Bool?
    let approvalRequired: Bool?
    let invitesEnabled: Bool?
    let urls: URLs
    let stats: Stats
    let thumbnail: URL?
    let contactAccount: Account?
}
