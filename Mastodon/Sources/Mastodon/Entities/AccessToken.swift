// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct AccessToken: Codable {
    public let scope: String
    public let tokenType: String
    public let accessToken: String
}
