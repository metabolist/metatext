// Copyright © 2020 Metabolist. All rights reserved.

import Foundation

extension FileManager {
    func databaseDirectoryURL() throws -> URL {
        let databaseDirectoryURL = try url(for: .applicationSupportDirectory,
                                           in: .userDomainMask,
                                           appropriateFor: nil,
                                           create: true)
            .appendingPathComponent("Database")
        var isDirectory: ObjCBool = false

        if !fileExists(atPath: databaseDirectoryURL.path, isDirectory: &isDirectory) {
            try createDirectory(at: databaseDirectoryURL,
                                withIntermediateDirectories: false,
                                attributes: [.protectionKey: FileProtectionType.complete])
        } else if !isDirectory.boolValue {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteFileExistsError, userInfo: nil)
        }

        return databaseDirectoryURL
    }
}
