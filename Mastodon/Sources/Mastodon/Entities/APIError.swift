// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct APIError: Error, Codable {
    public let error: String
}

extension APIError: LocalizedError {
    public var errorDescription: String? { error }
}
