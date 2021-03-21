// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

public struct APIError: Error, Codable {
    public let error: String
}

extension APIError: LocalizedError {
    public var errorDescription: String? { error }
}

public extension APIError {
    static let unableToFetchRemoteStatus =
        Self(error: NSLocalizedString("api-error.unable-to-fetch-remote-status", comment: ""))
}
