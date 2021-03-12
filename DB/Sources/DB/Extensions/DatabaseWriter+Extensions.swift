// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import Foundation
import GRDB

// swiftlint:disable:next line_length
// https://github.com/groue/GRDB.swift/blob/master/Documentation/SharingADatabase.md#how-to-limit-the-0xdead10cc-exception

extension DatabaseWriter {
    func mutatingPublisher<Output>(updates: @escaping (Database) throws -> Output) -> AnyPublisher<Never, Error> {
        let publisher = writePublisher(updates: updates)

        return publisher
            .tryCatch { error -> AnyPublisher<Output, Error> in
                if let databaseError = error as? DatabaseError, databaseError.isInterruptionError {
                    return NotificationCenter.default.publisher(for: Database.resumeNotification)
                        .timeout(.seconds(1), scheduler: DispatchQueue.global())
                        .flatMap { _ in publisher }
                        .eraseToAnyPublisher()
                } else {
                    throw error
                }
            }
            .retry(1)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }
}
