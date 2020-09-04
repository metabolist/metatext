// Copyright © 2020 Metabolist. All rights reserved.

import Foundation
import Keychain
import Secrets

extension Secrets {
    private static let passphraseByteCount = 64

    static func databasePassphrase(identityID: UUID?, keychain: Keychain.Type) throws -> String {
        let scopedSecrets: Secrets?

        if let identityID = identityID {
            scopedSecrets = Secrets(identityID: identityID, keychain: keychain)
        } else {
            scopedSecrets = nil
        }

        do {
            return try scopedSecrets?.item(.databasePassphrase) ?? unscopedItem(.databasePassphrase, keychain: keychain)
        } catch SecretsError.itemAbsent {
            var bytes = [Int8](repeating: 0, count: passphraseByteCount)
            let status = SecRandomCopyBytes(kSecRandomDefault, passphraseByteCount, &bytes)

            if status == errSecSuccess {
                let passphrase = Data(bytes: bytes, count: passphraseByteCount).base64EncodedString()

                if let scopedSecrets = scopedSecrets {
                    try scopedSecrets.set(passphrase, forItem: .databasePassphrase)
                } else {
                    try setUnscoped(passphrase, forItem: .databasePassphrase, keychain: keychain)
                }

                return passphrase
            } else {
                throw NSError(status: status)
            }
        }
    }
}
