// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension FileManager {
    enum DatabaseDirectoryError: Error {
        case containerURLNotFound
        case unexpectedFileExistsWithDBDirectoryName
    }

    func databaseDirectoryURL(name: String, appGroup: String) throws -> URL {
        guard let containerURL = containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            throw DatabaseDirectoryError.containerURLNotFound
        }

        let databaseDirectoryURL = containerURL.appendingPathComponent("DB")
        var isDirectory: ObjCBool = false

        if !fileExists(atPath: databaseDirectoryURL.path, isDirectory: &isDirectory) {
            try createDirectory(at: databaseDirectoryURL,
                                withIntermediateDirectories: false,
                                attributes: [.protectionKey: FileProtectionType.completeUnlessOpen])
        } else if !isDirectory.boolValue {
            throw DatabaseDirectoryError.unexpectedFileExistsWithDBDirectoryName
        }

        return databaseDirectoryURL.appendingPathComponent(name)
    }
}
