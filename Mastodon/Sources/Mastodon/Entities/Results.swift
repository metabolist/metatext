// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct Results: Codable {
    public let accounts: [Account]
    public let statuses: [Status]
    public let hashtags: [Tag]
}
